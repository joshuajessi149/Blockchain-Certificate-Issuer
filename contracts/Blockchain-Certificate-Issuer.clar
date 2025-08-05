(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-issuer (err u104))
(define-constant err-certificate-revoked (err u105))

(define-constant err-invalid-endorser (err u106))
(define-constant err-self-endorsement (err u107))
(define-constant err-already-endorsed (err u108))

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

(define-map certificate-templates
  uint
  {
    template-name: (string-ascii 100),
    course-name: (string-ascii 100),
    institution: (string-ascii 100),
    course-duration: uint,
    requirements: (string-ascii 200),
    credit-hours: uint,
    issuer: principal,
    is-active: bool,
    created-at: uint
  }
)

(define-map template-usage
  uint
  uint
)

(define-data-var last-template-id uint u0)

(define-public (create-certificate-template 
  (template-name (string-ascii 100))
  (course-name (string-ascii 100))
  (institution (string-ascii 100))
  (course-duration uint)
  (requirements (string-ascii 200))
  (credit-hours uint)
)
  (let
    (
      (template-id (+ (var-get last-template-id) u1))
      (issuer-info (map-get? authorized-issuers tx-sender))
    )
    (asserts! (is-some issuer-info) err-invalid-issuer)
    (asserts! (get is-active (unwrap-panic issuer-info)) err-unauthorized)
    
    (map-set certificate-templates
      template-id
      {
        template-name: template-name,
        course-name: course-name,
        institution: institution,
        course-duration: course-duration,
        requirements: requirements,
        credit-hours: credit-hours,
        issuer: tx-sender,
        is-active: true,
        created-at: stacks-block-height
      }
    )
    
    (map-set template-usage template-id u0)
    (var-set last-template-id template-id)
    (ok template-id)
  )
)

(define-public (toggle-template-status (template-id uint))
  (let
    (
      (template-data (map-get? certificate-templates template-id))
    )
    (asserts! (is-some template-data) err-not-found)
    (let
      (
        (template-info (unwrap-panic template-data))
      )
      (asserts! (is-eq tx-sender (get issuer template-info)) err-unauthorized)
      
      (ok (map-set certificate-templates
        template-id
        (merge template-info {is-active: (not (get is-active template-info))})
      ))
    )
  )
)

(define-public (issue-certificate-from-template
  (template-id uint)
  (recipient principal)
  (expiry-date (optional uint))
  (grade (optional (string-ascii 10)))
  (certificate-hash (string-ascii 64))
)
  (let
    (
      (template-data (map-get? certificate-templates template-id))
      (certificate-id (+ (var-get last-certificate-id) u1))
    )
    (asserts! (is-some template-data) err-not-found)
    (let
      (
        (template-info (unwrap-panic template-data))
      )
      (asserts! (is-eq tx-sender (get issuer template-info)) err-unauthorized)
      (asserts! (get is-active template-info) err-unauthorized)
      (asserts! (is-none (map-get? certificate-verification certificate-hash)) err-already-exists)
      
      (try! (nft-mint? certificate certificate-id recipient))
      
      (map-set certificates
        certificate-id
        {
          recipient: recipient,
          issuer: tx-sender,
          course-name: (get course-name template-info),
          institution: (get institution template-info),
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
      
      (let
        (
          (current-usage (default-to u0 (map-get? template-usage template-id)))
        )
        (map-set template-usage template-id (+ current-usage u1))
      )
      
      (var-set last-certificate-id certificate-id)
      (ok certificate-id)
    )
  )
)

(define-read-only (get-certificate-template (template-id uint))
  (map-get? certificate-templates template-id)
)

(define-read-only (get-template-usage-count (template-id uint))
  (default-to u0 (map-get? template-usage template-id))
)

(define-read-only (get-last-template-id)
  (var-get last-template-id)
)


(define-map certified-endorsers
  principal
  {
    profession: (string-ascii 50),
    organization: (string-ascii 100),
    verified-at: uint,
    endorsement-count: uint,
    is-active: bool
  }
)

(define-map certificate-endorsements
  {cert-id: uint, endorser: principal}
  {
    endorsement-text: (string-ascii 200),
    skill-rating: uint,
    endorsed-at: uint,
    endorser-profession: (string-ascii 50)
  }
)

(define-map endorsement-counts
  uint
  uint
)

(define-public (authorize-endorser 
  (endorser principal) 
  (profession (string-ascii 50)) 
  (organization (string-ascii 100))
)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set certified-endorsers
      endorser
      {
        profession: profession,
        organization: organization,
        verified-at: stacks-block-height,
        endorsement-count: u0,
        is-active: true
      }
    ))
  )
)

(define-public (endorse-certificate 
  (certificate-id uint)
  (endorsement-text (string-ascii 200))
  (skill-rating uint)
)
  (let
    (
      (certificate-data (map-get? certificates certificate-id))
      (endorser-info (map-get? certified-endorsers tx-sender))
      (endorsement-key {cert-id: certificate-id, endorser: tx-sender})
    )
    (asserts! (is-some certificate-data) err-not-found)
    (asserts! (is-some endorser-info) err-invalid-endorser)
    (asserts! (get is-active (unwrap-panic endorser-info)) err-unauthorized)
    (asserts! (<= skill-rating u10) err-unauthorized)
    (asserts! (> skill-rating u0) err-unauthorized)
    (asserts! (not (is-eq tx-sender (get recipient (unwrap-panic certificate-data)))) err-self-endorsement)
    (asserts! (is-none (map-get? certificate-endorsements endorsement-key)) err-already-endorsed)
    
    (map-set certificate-endorsements
      endorsement-key
      {
        endorsement-text: endorsement-text,
        skill-rating: skill-rating,
        endorsed-at: stacks-block-height,
        endorser-profession: (get profession (unwrap-panic endorser-info))
      }
    )
    
    (let
      (
        (current-count (default-to u0 (map-get? endorsement-counts certificate-id)))
        (endorser-data (unwrap-panic endorser-info))
      )
      (map-set endorsement-counts certificate-id (+ current-count u1))
      (map-set certified-endorsers
        tx-sender
        (merge endorser-data {endorsement-count: (+ (get endorsement-count endorser-data) u1)})
      )
    )
    (ok true)
  )
)

(define-read-only (get-certificate-endorsements (certificate-id uint))
  (map-get? endorsement-counts certificate-id)
)

(define-read-only (get-specific-endorsement (certificate-id uint) (endorser principal))
  (map-get? certificate-endorsements {cert-id: certificate-id, endorser: endorser})
)

(define-read-only (get-endorser-info (endorser principal))
  (map-get? certified-endorsers endorser)
)