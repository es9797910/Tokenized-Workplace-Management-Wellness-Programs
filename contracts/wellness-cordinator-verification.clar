;; Wellness Coordinator Verification Contract
;; Manages the registration, verification, and role management of wellness coordinators

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_EXISTS (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_STATUS (err u103))

;; Data Variables
(define-data-var next-coordinator-id uint u1)

;; Data Maps
(define-map coordinators
  { coordinator-id: uint }
  {
    address: principal,
    name: (string-ascii 50),
    certification: (string-ascii 100),
    status: (string-ascii 20),
    registered-at: uint,
    verified-at: (optional uint),
    verifier: (optional principal)
  }
)

(define-map coordinator-by-address
  { address: principal }
  { coordinator-id: uint }
)

(define-map coordinator-permissions
  { coordinator-id: uint }
  {
    can-create-programs: bool,
    can-verify-participation: bool,
    can-access-health-data: bool,
    max-program-budget: uint
  }
)

;; Public Functions

;; Register a new wellness coordinator
(define-public (register-coordinator (name (string-ascii 50)) (certification (string-ascii 100)))
  (let
    (
      (coordinator-id (var-get next-coordinator-id))
      (caller tx-sender)
    )
    ;; Check if coordinator already exists
    (asserts! (is-none (map-get? coordinator-by-address { address: caller })) ERR_ALREADY_EXISTS)

    ;; Store coordinator data
    (map-set coordinators
      { coordinator-id: coordinator-id }
      {
        address: caller,
        name: name,
        certification: certification,
        status: "pending",
        registered-at: block-height,
        verified-at: none,
        verifier: none
      }
    )

    ;; Map address to coordinator ID
    (map-set coordinator-by-address
      { address: caller }
      { coordinator-id: coordinator-id }
    )

    ;; Set default permissions
    (map-set coordinator-permissions
      { coordinator-id: coordinator-id }
      {
        can-create-programs: false,
        can-verify-participation: false,
        can-access-health-data: false,
        max-program-budget: u0
      }
    )

    ;; Increment next ID
    (var-set next-coordinator-id (+ coordinator-id u1))

    (ok coordinator-id)
  )
)

;; Verify a coordinator (only contract owner)
(define-public (verify-coordinator (coordinator-id uint))
  (let
    (
      (coordinator (unwrap! (map-get? coordinators { coordinator-id: coordinator-id }) ERR_NOT_FOUND))
    )
    ;; Only contract owner can verify
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    ;; Update coordinator status
    (map-set coordinators
      { coordinator-id: coordinator-id }
      (merge coordinator {
        status: "verified",
        verified-at: (some block-height),
        verifier: (some tx-sender)
      })
    )

    ;; Grant basic permissions
    (map-set coordinator-permissions
      { coordinator-id: coordinator-id }
      {
        can-create-programs: true,
        can-verify-participation: true,
        can-access-health-data: false,
        max-program-budget: u10000
      }
    )

    (ok true)
  )
)

;; Update coordinator permissions
(define-public (update-permissions
  (coordinator-id uint)
  (can-create-programs bool)
  (can-verify-participation bool)
  (can-access-health-data bool)
  (max-program-budget uint)
)
  (let
    (
      (coordinator (unwrap! (map-get? coordinators { coordinator-id: coordinator-id }) ERR_NOT_FOUND))
    )
    ;; Only contract owner can update permissions
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    ;; Coordinator must be verified
    (asserts! (is-eq (get status coordinator) "verified") ERR_INVALID_STATUS)

    ;; Update permissions
    (map-set coordinator-permissions
      { coordinator-id: coordinator-id }
      {
        can-create-programs: can-create-programs,
        can-verify-participation: can-verify-participation,
        can-access-health-data: can-access-health-data,
        max-program-budget: max-program-budget
      }
    )

    (ok true)
  )
)

;; Revoke coordinator access
(define-public (revoke-coordinator (coordinator-id uint))
  (let
    (
      (coordinator (unwrap! (map-get? coordinators { coordinator-id: coordinator-id }) ERR_NOT_FOUND))
    )
    ;; Only contract owner can revoke
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    ;; Update status to revoked
    (map-set coordinators
      { coordinator-id: coordinator-id }
      (merge coordinator { status: "revoked" })
    )

    ;; Remove all permissions
    (map-set coordinator-permissions
      { coordinator-id: coordinator-id }
      {
        can-create-programs: false,
        can-verify-participation: false,
        can-access-health-data: false,
        max-program-budget: u0
      }
    )

    (ok true)
  )
)

;; Read-only Functions

;; Get coordinator by ID
(define-read-only (get-coordinator (coordinator-id uint))
  (map-get? coordinators { coordinator-id: coordinator-id })
)

;; Get coordinator by address
(define-read-only (get-coordinator-by-address (address principal))
  (match (map-get? coordinator-by-address { address: address })
    coordinator-ref (map-get? coordinators { coordinator-id: (get coordinator-id coordinator-ref) })
    none
  )
)

;; Get coordinator permissions
(define-read-only (get-coordinator-permissions (coordinator-id uint))
  (map-get? coordinator-permissions { coordinator-id: coordinator-id })
)

;; Check if address is verified coordinator
(define-read-only (is-verified-coordinator (address principal))
  (match (get-coordinator-by-address address)
    coordinator (is-eq (get status coordinator) "verified")
    false
  )
)

;; Check specific permission
(define-read-only (has-permission (coordinator-id uint) (permission (string-ascii 30)))
  (match (map-get? coordinator-permissions { coordinator-id: coordinator-id })
    permissions
    (if (is-eq permission "create-programs")
      (get can-create-programs permissions)
      (if (is-eq permission "verify-participation")
        (get can-verify-participation permissions)
        (if (is-eq permission "access-health-data")
          (get can-access-health-data permissions)
          false
        )
      )
    )
    false
  )
)
