;; Commitment Registry System

;; ==========================================
;; ACTIVITY PRIORITY MANAGEMENT
;; ==========================================
;; Storage for activity significance levels
;; Enables advanced filtering and sorting capabilities
(define-map activity-priority-levels
    principal
    {
        priority-score: uint
    }
)

;; ==========================================
;; CORE DATA STRUCTURES
;; ==========================================
;; Primary data vault for activity information
;; Associates blockchain participants with their activities
(define-map activity-vault
    principal
    {
        description: (string-ascii 100),
        status-complete: bool
    }
)

;; ==========================================
;; OPERATIONAL STATUS CODES
;; ==========================================
;; Standard response indicators for various processing outcomes
(define-constant RECORD_NOT_FOUND (err u404))
(define-constant DUPLICATE_RECORD_ERROR (err u409))
(define-constant INVALID_DATA_FORMAT (err u400))


;; ==========================================
;; DEADLINE TRACKING MECHANISM
;; ==========================================
;; Centralized deadline monitoring system
;; Maintains temporal boundaries for activities
(define-map activity-deadlines
    principal
    {
        deadline-block: uint,
        alert-triggered: bool
    }
)


;; ==========================================
;; DATA VERIFICATION UTILITIES
;; ==========================================
;; Public function for system integrity verification
;; Provides status information without state modifications
(define-public (verify-activity-existence)
    (let
        (
            (user-id tx-sender)
            (current-record (map-get? activity-vault user-id))
        )
        (if (is-some current-record)
            (let
                (
                    (activity-data (unwrap! current-record RECORD_NOT_FOUND))
                    (description-text (get description activity-data))
                    (completion-status (get status-complete activity-data))
                )
                (ok {
                    record-exists: true,
                    text-length: (len description-text),
                    completion-flag: completion-status
                })
            )
            (ok {
                record-exists: false,
                text-length: u0,
                completion-flag: false
            })
        )
    )
)

;; ==========================================
;; DATA RETRIEVAL FUNCTIONS
;; ==========================================
;; Read-only function for comprehensive activity data access
(define-read-only (retrieve-activity-details (user-id principal))
    (match (map-get? activity-vault user-id)
        record (ok {
            description: (get description record),
            status-complete: (get status-complete record)
        })
        RECORD_NOT_FOUND
    )
)

;; Specialized status query function
;; Efficient method for checking only completion state
(define-read-only (check-activity-status (user-id principal))
    (match (map-get? activity-vault user-id)
        record (ok (get status-complete record))
        RECORD_NOT_FOUND
    )
)

;; ==========================================
;; ACTIVITY CREATION OPERATIONS
;; ==========================================
;; Public function to establish new activity records
(define-public (register-activity 
    (description-text (string-ascii 100)))
    (let
        (
            (user-id tx-sender)
            (existing-record (map-get? activity-vault user-id))
        )
        (if (is-none existing-record)
            (begin
                (if (is-eq description-text "")
                    (err INVALID_DATA_FORMAT)
                    (begin
                        (map-set activity-vault user-id
                            {
                                description: description-text,
                                status-complete: false
                            }
                        )
                        (ok "Activity successfully registered in system.")
                    )
                )
            )
            (err DUPLICATE_RECORD_ERROR)
        )
    )
)

;; ==========================================
;; ACTIVITY MODIFICATION FUNCTIONS
;; ==========================================
;; Public function for updating existing activity records
(define-public (modify-activity
    (description-text (string-ascii 100))
    (status-complete bool))
    (let
        (
            (user-id tx-sender)
            (existing-record (map-get? activity-vault user-id))
        )
        (if (is-some existing-record)
            (begin
                (if (is-eq description-text "")
                    (err INVALID_DATA_FORMAT)
                    (begin
                        (if (or (is-eq status-complete true) (is-eq status-complete false))
                            (begin
                                (map-set activity-vault user-id
                                    {
                                        description: description-text,
                                        status-complete: status-complete
                                    }
                                )
                                (ok "Activity successfully modified in system.")
                            )
                            (err INVALID_DATA_FORMAT)
                        )
                    )
                )
            )
            (err RECORD_NOT_FOUND)
        )
    )
)

;; ==========================================
;; ACTIVITY REMOVAL OPERATIONS
;; ==========================================
;; Public function to purge activity records
(define-public (purge-activity)
    (let
        (
            (user-id tx-sender)
            (existing-record (map-get? activity-vault user-id))
        )
        (if (is-some existing-record)
            (begin
                (map-delete activity-vault user-id)
                (ok "Activity successfully removed from system.")
            )
            (err RECORD_NOT_FOUND)
        )
    )
)

;; ==========================================
;; ADVANCED ACTIVITY MANAGEMENT
;; ==========================================
;; Public function for establishing temporal constraints
;; Sets blockchain-based deadline for completion tracking
(define-public (configure-activity-timeframe (block-countdown uint))
    (let
        (
            (user-id tx-sender)
            (existing-record (map-get? activity-vault user-id))
            (target-completion-block (+ block-height block-countdown))
        )
        (if (is-some existing-record)
            (if (> block-countdown u0)
                (begin
                    (map-set activity-deadlines user-id
                        {
                            deadline-block: target-completion-block,
                            alert-triggered: false
                        }
                    )
                    (ok "Activity timeframe successfully configured.")
                )
                (err INVALID_DATA_FORMAT)
            )
            (err RECORD_NOT_FOUND)
        )
    )
)

;; ==========================================
;; PRIORITY CLASSIFICATION SYSTEM
;; ==========================================
;; Public function for priority classification
;; Implements three-tier priority system (1=low, 2=medium, 3=high)
(define-public (assign-activity-priority (priority-level uint))
    (let
        (
            (user-id tx-sender)
            (existing-record (map-get? activity-vault user-id))
        )
        (if (is-some existing-record)
            (if (and (>= priority-level u1) (<= priority-level u3))
                (begin
                    (map-set activity-priority-levels user-id
                        {
                            priority-score: priority-level
                        }
                    )
                    (ok "Activity priority level successfully assigned.")
                )
                (err INVALID_DATA_FORMAT)
            )
            (err RECORD_NOT_FOUND)
        )
    )
)

;; ==========================================
;; COLLABORATIVE FUNCTIONS
;; ==========================================
;; Public function enabling workload distribution
;; Allows authorized users to create activities for others
(define-public (assign-activity
    (target-user principal)
    (description-text (string-ascii 100)))
    (let
        (
            (existing-record (map-get? activity-vault target-user))
        )
        (if (is-none existing-record)
            (begin
                (if (is-eq description-text "")
                    (err INVALID_DATA_FORMAT)
                    (begin
                        (map-set activity-vault target-user
                            {
                                description: description-text,
                                status-complete: false
                            }
                        )
                        (ok "Activity successfully assigned to recipient.")
                    )
                )
            )
            (err DUPLICATE_RECORD_ERROR)
        )
    )
)

