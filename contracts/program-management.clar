;; Program Management Contract
;; Manages wellness programs, their lifecycle, and resource allocation

;; Constants
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_NOT_FOUND (err u201))
(define-constant ERR_INVALID_STATUS (err u202))
(define-constant ERR_INSUFFICIENT_BUDGET (err u203))
(define-constant ERR_INVALID_DATES (err u204))

;; Data Variables
(define-data-var next-program-id uint u1)

;; Data Maps
(define-map programs
  { program-id: uint }
  {
    coordinator-address: principal,
    name: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 50),
    start-date: uint,
    end-date: uint,
    max-participants: uint,
    current-participants: uint,
    budget: uint,
    spent-budget: uint,
    status: (string-ascii 20),
    created-at: uint
  }
)

(define-map program-requirements
  { program-id: uint }
  {
    min-participation-days: uint,
    required-activities: (list 10 (string-ascii 50)),
    health-metrics-required: bool,
    completion-threshold: uint
  }
)

(define-map program-rewards
  { program-id: uint }
  {
    participation-token-rate: uint,
    completion-bonus: uint,
    milestone-rewards: (list 5 uint),
    coordinator-fee: uint
  }
)

(define-map authorized-coordinators
  { coordinator-address: principal }
  {
    is-verified: bool,
    max-budget: uint,
    programs-created: uint
  }
)

;; Public Functions

;; Add authorized coordinator (contract owner only)
(define-public (add-authorized-coordinator (coordinator-address principal) (max-budget uint))
  (begin
    ;; Only contract owner can add coordinators
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)

    ;; Add coordinator
    (map-set authorized-coordinators
      { coordinator-address: coordinator-address }
      {
        is-verified: true,
        max-budget: max-budget,
        programs-created: u0
      }
    )

    (ok true)
  )
)

;; Create a new wellness program
(define-public (create-program
  (name (string-ascii 100))
  (description (string-ascii 500))
  (category (string-ascii 50))
  (start-date uint)
  (end-date uint)
  (max-participants uint)
  (budget uint)
  (min-participation-days uint)
  (required-activities (list 10 (string-ascii 50)))
  (health-metrics-required bool)
  (completion-threshold uint)
  (participation-token-rate uint)
  (completion-bonus uint)
)
  (let
    (
      (program-id (var-get next-program-id))
      (coordinator-auth (unwrap! (map-get? authorized-coordinators { coordinator-address: tx-sender }) ERR_UNAUTHORIZED))
    )
    ;; Verify coordinator is authorized
    (asserts! (get is-verified coordinator-auth) ERR_UNAUTHORIZED)

    ;; Verify budget doesn't exceed coordinator's limit
    (asserts! (<= budget (get max-budget coordinator-auth)) ERR_INSUFFICIENT_BUDGET)

    ;; Verify dates are valid
    (asserts! (< start-date end-date) ERR_INVALID_DATES)
    (asserts! (>= start-date block-height) ERR_INVALID_DATES)

    ;; Create program
    (map-set programs
      { program-id: program-id }
      {
        coordinator-address: tx-sender,
        name: name,
        description: description,
        category: category,
        start-date: start-date,
        end-date: end-date,
        max-participants: max-participants,
        current-participants: u0,
        budget: budget,
        spent-budget: u0,
        status: "active",
        created-at: block-height
      }
    )

    ;; Set program requirements
    (map-set program-requirements
      { program-id: program-id }
      {
        min-participation-days: min-participation-days,
        required-activities: required-activities,
        health-metrics-required: health-metrics-required,
        completion-threshold: completion-threshold
      }
    )

    ;; Set program rewards
    (map-set program-rewards
      { program-id: program-id }
      {
        participation-token-rate: participation-token-rate,
        completion-bonus: completion-bonus,
        milestone-rewards: (list u50 u100 u200 u300 u500),
        coordinator-fee: (/ budget u20) ;; 5% coordinator fee
      }
    )

    ;; Update coordinator stats
    (map-set authorized-coordinators
      { coordinator-address: tx-sender }
      (merge coordinator-auth {
        programs-created: (+ (get programs-created coordinator-auth) u1)
      })
    )

    ;; Increment next program ID
    (var-set next-program-id (+ program-id u1))

    (ok program-id)
  )
)

;; Update program details
(define-public (update-program
  (program-id uint)
  (name (string-ascii 100))
  (description (string-ascii 500))
  (max-participants uint)
)
  (let
    (
      (program (unwrap! (map-get? programs { program-id: program-id }) ERR_NOT_FOUND))
    )
    ;; Verify caller is the program coordinator
    (asserts! (is-eq tx-sender (get coordinator-address program)) ERR_UNAUTHORIZED)

    ;; Program must be active
    (asserts! (is-eq (get status program) "active") ERR_INVALID_STATUS)

    ;; Update program
    (map-set programs
      { program-id: program-id }
      (merge program {
        name: name,
        description: description,
        max-participants: max-participants
      })
    )

    (ok true)
  )
)

;; Close program enrollment
(define-public (close-program (program-id uint))
  (let
    (
      (program (unwrap! (map-get? programs { program-id: program-id }) ERR_NOT_FOUND))
    )
    ;; Verify caller is the program coordinator
    (asserts! (is-eq tx-sender (get coordinator-address program)) ERR_UNAUTHORIZED)

    ;; Update program status
    (map-set programs
      { program-id: program-id }
      (merge program { status: "closed" })
    )

    (ok true)
  )
)

;; Update participant count (internal function)
(define-public (update-participant-count (program-id uint) (change int))
  (let
    (
      (program (unwrap! (map-get? programs { program-id: program-id }) ERR_NOT_FOUND))
      (new-count (if (> change 0)
                   (+ (get current-participants program) (to-uint change))
                   (- (get current-participants program) (to-uint (* change -1)))))
    )
    ;; Update participant count
    (map-set programs
      { program-id: program-id }
      (merge program { current-participants: new-count })
    )

    (ok new-count)
  )
)

;; Update spent budget
(define-public (update-spent-budget (program-id uint) (amount uint))
  (let
    (
      (program (unwrap! (map-get? programs { program-id: program-id }) ERR_NOT_FOUND))
      (new-spent (+ (get spent-budget program) amount))
    )
    ;; Check budget limit
    (asserts! (<= new-spent (get budget program)) ERR_INSUFFICIENT_BUDGET)

    ;; Update spent budget
    (map-set programs
      { program-id: program-id }
      (merge program { spent-budget: new-spent })
    )

    (ok new-spent)
  )
)

;; Data variable for contract owner
(define-data-var contract-owner principal tx-sender)

;; Read-only Functions

;; Get program details
(define-read-only (get-program (program-id uint))
  (map-get? programs { program-id: program-id })
)

;; Get program requirements
(define-read-only (get-program-requirements (program-id uint))
  (map-get? program-requirements { program-id: program-id })
)

;; Get program rewards
(define-read-only (get-program-rewards (program-id uint))
  (map-get? program-rewards { program-id: program-id })
)

;; Check if program is active
(define-read-only (is-program-active (program-id uint))
  (match (map-get? programs { program-id: program-id })
    program (and
      (is-eq (get status program) "active")
      (>= block-height (get start-date program))
      (<= block-height (get end-date program))
    )
    false
  )
)

;; Check if program has capacity
(define-read-only (has-capacity (program-id uint))
  (match (map-get? programs { program-id: program-id })
    program (< (get current-participants program) (get max-participants program))
    false
  )
)

;; Get remaining budget
(define-read-only (get-remaining-budget (program-id uint))
  (match (map-get? programs { program-id: program-id })
    program (- (get budget program) (get spent-budget program))
    u0
  )
)

;; Check if address is authorized coordinator
(define-read-only (is-authorized-coordinator (coordinator-address principal))
  (match (map-get? authorized-coordinators { coordinator-address: coordinator-address })
    auth (get is-verified auth)
    false
  )
)
