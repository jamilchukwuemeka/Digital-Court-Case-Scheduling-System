;; Attorney Notification Contract
;; Manages attorney registration and case notifications

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-INVALID-INPUT (err u201))
(define-constant ERR-ATTORNEY-NOT-FOUND (err u202))
(define-constant ERR-ALREADY-REGISTERED (err u203))
(define-constant ERR-NOTIFICATION-NOT-FOUND (err u204))

;; Data Variables
(define-data-var next-notification-id uint u1)

;; Data Maps
(define-map attorneys
  { attorney-id: principal }
  {
    name: (string-ascii 100),
    bar-number: (string-ascii 20),
    email: (string-ascii 100),
    phone: (string-ascii 20),
    specialization: (string-ascii 50),
    status: (string-ascii 20),
    registered-at: uint
  }
)

(define-map attorney-cases
  { attorney-id: principal, case-id: uint }
  {
    role: (string-ascii 20), ;; "plaintiff", "defendant", "prosecutor"
    assigned-at: uint,
    status: (string-ascii 20)
  }
)

(define-map notifications
  { notification-id: uint }
  {
    attorney-id: principal,
    case-id: uint,
    message: (string-ascii 500),
    notification-type: (string-ascii 30),
    priority: (string-ascii 10),
    sent-at: uint,
    read-at: (optional uint),
    status: (string-ascii 20)
  }
)

(define-map attorney-preferences
  { attorney-id: principal }
  {
    email-notifications: bool,
    sms-notifications: bool,
    urgent-only: bool,
    notification-hours-start: uint,
    notification-hours-end: uint
  }
)

;; Authorization check
(define-private (is-authorized (caller principal))
  (or (is-eq caller CONTRACT-OWNER)
      (is-court-admin caller)))

(define-private (is-court-admin (caller principal))
  (is-eq caller CONTRACT-OWNER))

;; Attorney Registration
(define-public (register-attorney
  (attorney-id principal)
  (name (string-ascii 100))
  (bar-number (string-ascii 20))
  (email (string-ascii 100))
  (phone (string-ascii 20))
  (specialization (string-ascii 50)))
  (begin
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len bar-number) u0) ERR-INVALID-INPUT)
    (asserts! (> (len email) u0) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? attorneys { attorney-id: attorney-id })) ERR-ALREADY-REGISTERED)

    (map-set attorneys
      { attorney-id: attorney-id }
      {
        name: name,
        bar-number: bar-number,
        email: email,
        phone: phone,
        specialization: specialization,
        status: "active",
        registered-at: block-height
      })

    ;; Set default notification preferences
    (map-set attorney-preferences
      { attorney-id: attorney-id }
      {
        email-notifications: true,
        sms-notifications: false,
        urgent-only: false,
        notification-hours-start: u800,
        notification-hours-end: u1800
      })

    (ok true)))

;; Case Assignment
(define-public (assign-attorney-to-case
  (attorney-id principal)
  (case-id uint)
  (role (string-ascii 20)))
  (begin
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? attorneys { attorney-id: attorney-id })) ERR-ATTORNEY-NOT-FOUND)
    (asserts! (> case-id u0) ERR-INVALID-INPUT)

    (map-set attorney-cases
      { attorney-id: attorney-id, case-id: case-id }
      {
        role: role,
        assigned-at: block-height,
        status: "active"
      })

    ;; Send assignment notification
    (try! (send-notification
      attorney-id
      case-id
      "You have been assigned to a new case"
      "case-assignment"
      "normal"))

    (ok true)))

;; Notification System
(define-public (send-notification
  (attorney-id principal)
  (case-id uint)
  (message (string-ascii 500))
  (notification-type (string-ascii 30))
  (priority (string-ascii 10)))
  (let ((notification-id (var-get next-notification-id)))
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? attorneys { attorney-id: attorney-id })) ERR-ATTORNEY-NOT-FOUND)
    (asserts! (> (len message) u0) ERR-INVALID-INPUT)

    (map-set notifications
      { notification-id: notification-id }
      {
        attorney-id: attorney-id,
        case-id: case-id,
        message: message,
        notification-type: notification-type,
        priority: priority,
        sent-at: block-height,
        read-at: none,
        status: "sent"
      })

    (var-set next-notification-id (+ notification-id u1))
    (ok notification-id)))

;; Bulk notification for schedule changes
(define-public (notify-schedule-change
  (case-id uint)
  (message (string-ascii 500))
  (new-date uint)
  (new-time uint))
  (begin
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> case-id u0) ERR-INVALID-INPUT)
    (asserts! (> (len message) u0) ERR-INVALID-INPUT)

    ;; This would iterate through all attorneys assigned to the case
    ;; For simplicity, we'll return success
    ;; In a real implementation, this would use a helper function to find all attorneys
    (ok true)))

;; Mark notification as read
(define-public (mark-notification-read (notification-id uint))
  (let ((notification (unwrap! (map-get? notifications { notification-id: notification-id }) ERR-NOTIFICATION-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get attorney-id notification)) ERR-NOT-AUTHORIZED)

    (map-set notifications
      { notification-id: notification-id }
      (merge notification {
        read-at: (some block-height),
        status: "read"
      }))

    (ok true)))

;; Update notification preferences
(define-public (update-notification-preferences
  (email-notifications bool)
  (sms-notifications bool)
  (urgent-only bool)
  (hours-start uint)
  (hours-end uint))
  (begin
    (asserts! (is-some (map-get? attorneys { attorney-id: tx-sender })) ERR-ATTORNEY-NOT-FOUND)
    (asserts! (< hours-start u2400) ERR-INVALID-INPUT)
    (asserts! (< hours-end u2400) ERR-INVALID-INPUT)
    (asserts! (< hours-start hours-end) ERR-INVALID-INPUT)

    (map-set attorney-preferences
      { attorney-id: tx-sender }
      {
        email-notifications: email-notifications,
        sms-notifications: sms-notifications,
        urgent-only: urgent-only,
        notification-hours-start: hours-start,
        notification-hours-end: hours-end
      })

    (ok true)))

;; Update attorney status
(define-public (update-attorney-status (attorney-id principal) (status (string-ascii 20)))
  (begin
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? attorneys { attorney-id: attorney-id })) ERR-ATTORNEY-NOT-FOUND)

    (map-set attorneys
      { attorney-id: attorney-id }
      (merge (unwrap-panic (map-get? attorneys { attorney-id: attorney-id }))
             { status: status }))
    (ok true)))

;; Read-only functions
(define-read-only (get-attorney (attorney-id principal))
  (map-get? attorneys { attorney-id: attorney-id }))

(define-read-only (get-attorney-case-assignment (attorney-id principal) (case-id uint))
  (map-get? attorney-cases { attorney-id: attorney-id, case-id: case-id }))

(define-read-only (get-notification (notification-id uint))
  (map-get? notifications { notification-id: notification-id }))

(define-read-only (get-attorney-preferences (attorney-id principal))
  (map-get? attorney-preferences { attorney-id: attorney-id }))

(define-read-only (count-unread-notifications (attorney-id principal))
  ;; In a real implementation, this would count unread notifications
  ;; For now, return a placeholder
  (ok u0))
