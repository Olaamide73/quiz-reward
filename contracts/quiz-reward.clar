;; Define contract owner
(define-constant contract-owner tx-sender)

(define-constant QUIZ_QUESTION "What is the capital of France?")

;; Store the hashed correct answer (e.g., sha256 of "Paris")
(define-constant CORRECT_ANSWER_HASH
  (sha256 0x5061726973)) ;; "Paris" in hex ascii

(define-map answered {user: principal} {answered: bool})

(define-data-var reward-amount uint u1000000) ;; 0.001 STX reward (1,000,000 microSTX)

;; Check if the given answer is correct by hashing and comparing
(define-read-only (check-answer (answer (buff 64)))
  (ok (is-eq (sha256 answer) CORRECT_ANSWER_HASH))
)

;; Submit answer and get reward if correct
(define-public (submit-answer (answer (buff 64)))
  (begin
    (if (is-some (map-get? answered {user: tx-sender}))
      (err u0) ;; Use a uint error code for consistency
      (let ((correct (is-eq (sha256 answer) CORRECT_ANSWER_HASH)))
        (if correct
          (begin
            (map-set answered {user: tx-sender} {answered: true})
            (try! (as-contract (stx-transfer? (var-get reward-amount) tx-sender contract-caller)))
            (ok u1) ;; Use a uint success code
          )
          (err u1) ;; Use a uint error code for wrong answer
        )
      )
    )
  )
)

;; Owner can set reward amount
(define-public (set-reward (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err u3)) ;; u3 for unauthorized
    (asserts! (> amount u0) (err u4)) ;; u4 for invalid amount
    (ok (var-set reward-amount amount))
  )
)

;; Allow owner to withdraw remaining funds
(define-public (withdraw (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err u3)) ;; u3 for unauthorized
    (asserts! (> amount u0) (err u4)) ;; u4 for invalid amount
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    (ok amount)
  )
)
