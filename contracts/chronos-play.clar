;; Title: ChronosPlay
;; Summary: Revolutionary time-locked gaming ecosystem powered by blockchain technology
;; Description: ChronosPlay introduces a groundbreaking approach to gaming subscriptions where 
;;              time truly becomes your currency. This smart contract creates an immersive 
;;              subscription model that leverages Stacks blockchain's block-height mechanism 
;;              to deliver precise, trustless gaming access control. Players purchase gaming 
;;              time measured in blockchain blocks, ensuring transparent, verifiable playtime 
;;              allocation while enabling flexible tier-based progression systems.

;; CONSTANTS & ERROR HANDLING

(define-constant GAME_MASTER tx-sender)
(define-constant ERR_ACCESS_DENIED (err u200))
(define-constant ERR_INVALID_PLAY_DURATION (err u201))
(define-constant ERR_INSUFFICIENT_FUNDS (err u202))
(define-constant ERR_SUBSCRIPTION_ACTIVE (err u203))
(define-constant ERR_NO_SUBSCRIPTION (err u204))
(define-constant ERR_SUBSCRIPTION_EXPIRED (err u205))
(define-constant ERR_INVALID_TIER (err u206))
(define-constant ERR_INVALID_INPUT (err u207))
(define-constant ERR_OVERFLOW (err u208))

;; SECURITY CONSTANTS
(define-constant MAX_TIER_ID u100)
(define-constant MAX_COST_PER_BLOCK u1000000) ;; 1M STX per block max
(define-constant MAX_DURATION u525600) ;; ~10 years max
(define-constant MIN_COST_PER_BLOCK u1) ;; Minimum cost
(define-constant MAX_NAME_LENGTH u64)

;; STATE VARIABLES

(define-data-var game-master principal tx-sender)
(define-data-var next-player-id uint u1)
(define-data-var max-tier-id uint u2)

;; DATA STORAGE MAPS

(define-map gaming-tiers
  { tier-id: uint }
  {
    name: (string-ascii 64),
    cost-per-block: uint,
    minimum-duration: uint,
    maximum-duration: uint,
    active: bool,
  }
)

(define-map player-profiles
  { player: principal }
  {
    player-id: uint,
    tier-id: uint,
    start-block: uint,
    end-block: uint,
    auto-renew: bool,
    total-spent: uint,
  }
)

(define-map subscription-ledger
  { player-id: uint }
  {
    player: principal,
    tier-id: uint,
    start-block: uint,
    end-block: uint,
    auto-renew: bool,
    total-spent: uint,
    is-active: bool,
  }
)

;; TIER INITIALIZATION

;; Initialize Casual Explorer tier
(map-set gaming-tiers { tier-id: u1 } {
  name: "Casual Explorer",
  cost-per-block: u12,
  minimum-duration: u4320, ;; ~30 days
  maximum-duration: u52560, ;; ~365 days
  active: true,
})

;; Initialize Elite Commander tier
(map-set gaming-tiers { tier-id: u2 } {
  name: "Elite Commander",
  cost-per-block: u25,
  minimum-duration: u4320,
  maximum-duration: u52560,
  active: true,
})

;; VALIDATION HELPER FUNCTIONS

(define-private (is-valid-tier-id (tier-id uint))
  (and (> tier-id u0) (<= tier-id MAX_TIER_ID))
)

(define-private (is-valid-cost-per-block (cost uint))
  (and (>= cost MIN_COST_PER_BLOCK) (<= cost MAX_COST_PER_BLOCK))
)

(define-private (is-valid-duration (duration uint))
  (and (> duration u0) (<= duration MAX_DURATION))
)

(define-private (is-valid-duration-range
    (min-duration uint)
    (max-duration uint)
  )
  (and
    (is-valid-duration min-duration)
    (is-valid-duration max-duration)
    (<= min-duration max-duration)
  )
)

(define-private (safe-multiply
    (a uint)
    (b uint)
  )
  (let ((result (* a b)))
    (if (and (> a u0) (> b u0))
      ;; Check for overflow: if a * b / a != b, then overflow occurred
      (if (is-eq (/ result a) b)
        (ok result)
        ERR_OVERFLOW
      )
      (ok result)
    )
  )
)

(define-private (safe-add
    (a uint)
    (b uint)
  )
  (let ((result (+ a b)))
    (if (>= result a)
      (ok result)
      ERR_OVERFLOW
    )
  )
)

;; READ-ONLY FUNCTIONS

(define-read-only (get-gaming-tier (tier-id uint))
  (if (is-valid-tier-id tier-id)
    (map-get? gaming-tiers { tier-id: tier-id })
    none
  )
)

(define-read-only (get-player-profile (player principal))
  (map-get? player-profiles { player: player })
)

(define-read-only (get-subscription-by-id (player-id uint))
  (map-get? subscription-ledger { player-id: player-id })
)

(define-read-only (is-subscription-valid (player principal))
  (match (map-get? player-profiles { player: player })
    profile (>= (get end-block profile) stacks-block-height)
    false
  )
)

(define-read-only (get-play-blocks-remaining (player principal))
  (match (map-get? player-profiles { player: player })
    profile (if (>= (get end-block profile) stacks-block-height)
      (some (- (get end-block profile) stacks-block-height))
      (some u0)
    )
    none
  )
)

(define-read-only (calculate-subscription-cost
    (tier-id uint)
    (play-blocks uint)
  )
  (begin
    ;; Validate inputs
    (asserts! (is-valid-tier-id tier-id) ERR_INVALID_TIER)
    (asserts! (is-valid-duration play-blocks) ERR_INVALID_PLAY_DURATION)

    (match (map-get? gaming-tiers { tier-id: tier-id })
      tier (if (and
          (>= play-blocks (get minimum-duration tier))
          (<= play-blocks (get maximum-duration tier))
          (get active tier)
        )
        ;; Use safe multiplication to prevent overflow
        (safe-multiply (get cost-per-block tier) play-blocks)
        ERR_INVALID_PLAY_DURATION
      )
      ERR_INVALID_TIER
    )
  )
)

(define-read-only (get-game-master)
  (var-get game-master)
)

(define-read-only (get-max-tier-id)
  (var-get max-tier-id)
)

;; PUBLIC FUNCTIONS - PLAYER OPERATIONS

(define-public (join-realm
    (tier-id uint)
    (play-blocks uint)
    (auto-renew bool)
  )
  (let (
      (player tx-sender)
      (current-block stacks-block-height)
      (player-id (var-get next-player-id))
    )
    ;; Validate inputs first
    (asserts! (is-valid-tier-id tier-id) ERR_INVALID_TIER)
    (asserts! (is-valid-duration play-blocks) ERR_INVALID_PLAY_DURATION)

    ;; Check if player already has an active subscription
    (asserts! (not (is-subscription-valid player)) ERR_SUBSCRIPTION_ACTIVE)

    ;; Validate tier exists and calculate cost
    (match (calculate-subscription-cost tier-id play-blocks)
      total-cost (let (
        )
        ;; Safe addition for end block calculation
        (match (safe-add current-block play-blocks)
          end-block (begin
            ;; Create player profile with validated data
            (map-set player-profiles { player: player } {
              player-id: player-id,
              tier-id: tier-id,
              start-block: current-block,
              end-block: end-block,
              auto-renew: auto-renew,
              total-spent: total-cost,
            })

            ;; Create subscription ledger entry with validated data
            (map-set subscription-ledger { player-id: player-id } {
              player: player,
              tier-id: tier-id,
              start-block: current-block,
              end-block: end-block,
              auto-renew: auto-renew,
              total-spent: total-cost,
              is-active: true,
            })

            ;; Increment player ID counter
            (var-set next-player-id (+ player-id u1))

            ;; Transfer subscription fee
            (try! (stx-transfer? total-cost player (var-get game-master)))

            (ok player-id)
          )
          overflow-err (err overflow-err)
        )
      )
      cost-err (err cost-err)
    )
  )
)

(define-public (extend-playtime (additional-blocks uint))
  (let ((player tx-sender))
    ;; Validate input
    (asserts! (is-valid-duration additional-blocks) ERR_INVALID_PLAY_DURATION)

    (match (map-get? player-profiles { player: player })
      profile (let (
          (tier-id (get tier-id profile))
          (current-end (get end-block profile))
        )
        ;; Calculate additional cost with validated inputs
        (match (calculate-subscription-cost tier-id additional-blocks)
          additional-cost (begin
            ;; Safe addition for new end block and total spent
            (match (safe-add current-end additional-blocks)
              new-end (match (safe-add (get total-spent profile) additional-cost)
                new-total (begin
                  ;; Update player profile
                  (map-set player-profiles { player: player }
                    (merge profile {
                      end-block: new-end,
                      total-spent: new-total,
                    })
                  )

                  ;; Update subscription ledger
                  (map-set subscription-ledger { player-id: (get player-id profile) }
                    (merge
                      (unwrap-panic (map-get? subscription-ledger { player-id: (get player-id profile) })) {
                      end-block: new-end,
                      total-spent: new-total,
                    })
                  )

                  ;; Transfer additional cost
                  (try! (stx-transfer? additional-cost player (var-get game-master)))

                  (ok new-end)
                )
                overflow-err (err overflow-err)
              )
              overflow-err (err overflow-err)
            )
          )
          cost-err (err cost-err)
        )
      )
      ERR_NO_SUBSCRIPTION
    )
  )
)

(define-public (quit-realm)
  (let ((player tx-sender))
    (match (map-get? player-profiles { player: player })
      profile (begin
        ;; Mark subscription as inactive
        (map-set subscription-ledger { player-id: (get player-id profile) }
          (merge
            (unwrap-panic (map-get? subscription-ledger { player-id: (get player-id profile) })) {
            is-active: false,
            auto-renew: false,
          })
        )

        ;; Update player profile
        (map-set player-profiles { player: player }
          (merge profile {
            auto-renew: false,
            end-block: stacks-block-height, ;; End immediately
          })
        )

        (ok true)
      )
      ERR_NO_SUBSCRIPTION
    )
  )
)

(define-public (toggle-auto-renew)
  (let ((player tx-sender))
    (match (map-get? player-profiles { player: player })
      profile (let ((new-auto-renew (not (get auto-renew profile))))
        ;; Update player profile
        (map-set player-profiles { player: player }
          (merge profile { auto-renew: new-auto-renew })
        )

        ;; Update subscription ledger
        (map-set subscription-ledger { player-id: (get player-id profile) }
          (merge
            (unwrap-panic (map-get? subscription-ledger { player-id: (get player-id profile) })) { auto-renew: new-auto-renew }
          ))

        (ok new-auto-renew)
      )
      ERR_NO_SUBSCRIPTION
    )
  )
)