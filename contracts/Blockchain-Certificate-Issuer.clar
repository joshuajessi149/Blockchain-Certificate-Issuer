(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-issuer (err u104))
(define-constant err-certificate-revoked (err u105))

(define-non-fungible-token certificate uint)

(define-data-var last-certificate-id uint u0)

(define-map certificates
  uint
  {
    recipient: principal,
    issuer: principal,
    course-name: (string-ascii 100),
    institution: (string-ascii 100),
    issue-date: uint,
    expiry-date: (optional uint),
    grade: (optional (string-ascii 10)),
    certificate-hash: (string-ascii 64),
    is-revoked: bool
  }
)

(define-map authorized-issuers
  principal
  {
    institution-name: (string-ascii 100),
    is-active: bool,
    authorized-at: uint
  }
)

(define-map issuer-certificates
  {issuer: principal, cert-id: uint}
  bool
)

(define-map recipient-certificates
  {recipient: principal, cert-id: uint}
  bool
)

(define-map certificate-verification
  (string-ascii 64)
  uint
)

(define-public (authorize-issuer (issuer principal) (institution-name (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set authorized-issuers
      issuer
      {
        institution-name: institution-name,
        is-active: true,
        authorized-at: stacks-block-height
      }
    ))
  )
)

(define-public (revoke-issuer (issuer principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (match (map-get? authorized-issuers issuer)
      issuer-data (ok (map-set authorized-issuers
        issuer
        (merge issuer-data {is-active: false})
      ))
      err-not-found
    )
  )
)

(define-public (issue-certificate 
  (recipient principal)
  (course-name (string-ascii 100))
  (institution (string-ascii 100))
  (expiry-date (optional uint))
  (grade (optional (string-ascii 10)))
  (certificate-hash (string-ascii 64))
)
  (let
    (
      (certificate-id (+ (var-get last-certificate-id) u1))
      (issuer-info (map-get? authorized-issuers tx-sender))
    )
    (asserts! (is-some issuer-info) err-invalid-issuer)
    (asserts! (get is-active (unwrap-panic issuer-info)) err-unauthorized)
    (asserts! (is-none (map-get? certificate-verification certificate-hash)) err-already-exists)
    
    (try! (nft-mint? certificate certificate-id recipient))
    
    (map-set certificates
      certificate-id
      {
        recipient: recipient,
        issuer: tx-sender,
        course-name: course-name,
        institution: institution,
        issue-date: stacks-block-height,
        expiry-date: expiry-date,
        grade: grade,
        certificate-hash: certificate-hash,
        is-revoked: false
      }
    )
    
    (map-set issuer-certificates
      {issuer: tx-sender, cert-id: certificate-id}
      true
    )
    
    (map-set recipient-certificates
      {recipient: recipient, cert-id: certificate-id}
      true
    )
    
    (map-set certificate-verification certificate-hash certificate-id)
    
    (var-set last-certificate-id certificate-id)
    (ok certificate-id)
  )
)

(define-public (revoke-certificate (certificate-id uint))
  (let
    (
      (certificate-data (map-get? certificates certificate-id))
    )
    (asserts! (is-some certificate-data) err-not-found)
    (let
      (
        (cert-info (unwrap-panic certificate-data))
      )
      (asserts! (is-eq tx-sender (get issuer cert-info)) err-unauthorized)
      (asserts! (not (get is-revoked cert-info)) err-certificate-revoked)
      
      (ok (map-set certificates
        certificate-id
        (merge cert-info {is-revoked: true})
      ))
    )
  )
)

(define-public (transfer-certificate (certificate-id uint) (new-owner principal))
  (let
    (
      (certificate-data (map-get? certificates certificate-id))
    )
    (asserts! (is-some certificate-data) err-not-found)
    (let
      (
        (cert-info (unwrap-panic certificate-data))
      )
      (asserts! (is-eq tx-sender (get recipient cert-info)) err-unauthorized)
      (asserts! (not (get is-revoked cert-info)) err-certificate-revoked)
      
      (try! (nft-transfer? certificate certificate-id tx-sender new-owner))
      
      (map-delete recipient-certificates
        {recipient: tx-sender, cert-id: certificate-id}
      )
      
      (map-set recipient-certificates
        {recipient: new-owner, cert-id: certificate-id}
        true
      )
      
      (ok (map-set certificates
        certificate-id
        (merge cert-info {recipient: new-owner})
      ))
    )
  )
)

(define-read-only (get-certificate (certificate-id uint))
  (map-get? certificates certificate-id)
)

(define-read-only (get-certificate-owner (certificate-id uint))
  (nft-get-owner? certificate certificate-id)
)

(define-read-only (verify-certificate-by-hash (certificate-hash (string-ascii 64)))
  (match (map-get? certificate-verification certificate-hash)
    certificate-id (map-get? certificates certificate-id)
    none
  )
)

(define-read-only (is-certificate-valid (certificate-id uint))
  (match (map-get? certificates certificate-id)
    certificate-data 
      (let
        (
          (current-block stacks-block-height)
          (expiry (get expiry-date certificate-data))
          (is-revoked (get is-revoked certificate-data))
        )
        (and
          (not is-revoked)
          (match expiry
            expiry-block (<= current-block expiry-block)
            true
          )
        )
      )
    false
  )
)

(define-read-only (get-issuer-info (issuer principal))
  (map-get? authorized-issuers issuer)
)

(define-read-only (is-authorized-issuer (issuer principal))
  (match (map-get? authorized-issuers issuer)
    issuer-data (get is-active issuer-data)
    false
  )
)

(define-read-only (get-certificates-by-recipient (recipient principal) (certificate-id uint))
  (map-get? recipient-certificates {recipient: recipient, cert-id: certificate-id})
)

(define-read-only (get-certificates-by-issuer (issuer principal) (certificate-id uint))
  (map-get? issuer-certificates {issuer: issuer, cert-id: certificate-id})
)

(define-read-only (get-last-certificate-id)
  (var-get last-certificate-id)
)

(define-read-only (get-contract-owner)
  contract-owner
)
