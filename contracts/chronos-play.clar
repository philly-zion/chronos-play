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