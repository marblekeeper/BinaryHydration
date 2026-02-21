;; emit4.lisp
;; Bakes a Config Header, Text Arena, Numeric Arena, and Sentinel.

(defconstant +magic-number+ #x5A45524F) ; "ZERO"
(defconstant +version+ 4)

;; The Physical Configuration (The DNA)
(defconstant +msg-count+ 5)
(defconstant +msg-len+ 32)
(defconstant +data-count+ 16)
(defconstant +sentinel+ #xDEADBEEF)

;; =========================================================================
;; STATIC ANALYZER PASS
;; =========================================================================
(defun verify-geometry (messages active-index)
  (format t "[Analyzer] Verifying v~A geometry and limits...~%" +version+)
  (when (/= (length messages) +msg-count+)
    (error "[FATAL] Geometry mismatch. Expected ~A messages." +msg-count+))
  (when (or (< active-index 0) (>= active-index +msg-count+))
    (error "[FATAL] Active index ~A violates boundary limits." active-index))
  (loop for msg in messages for i from 0 do
        (when (>= (length msg) +msg-len+)
          (error "[FATAL] Message ~A overflows ~A-byte boundary." i +msg-len+)))
  (format t "[Analyzer] Geometry verified. DNA limits mapped.~%"))

;; =========================================================================
;; THE BAKE
;; =========================================================================
(defun write-uint32 (val stream)
  (write-byte (ldb (byte 8 0)  val) stream)
  (write-byte (ldb (byte 8 8)  val) stream)
  (write-byte (ldb (byte 8 16) val) stream)
  (write-byte (ldb (byte 8 24) val) stream))

(defun bake-universe (filename messages active-index)
  (verify-geometry messages active-index)
  
  (with-open-file (out filename :direction :output :element-type '(unsigned-byte 8) :if-exists :supersede)
    
    ;; 1. The Binary Configuration Header (24 bytes)
    ;; This tells C exactly what its limits are.
    (write-uint32 +magic-number+ out)
    (write-uint32 +version+ out)
    (write-uint32 +msg-count+ out)      ; Tell C the max messages
    (write-uint32 +msg-len+ out)        ; Tell C the message length
    (write-uint32 +data-count+ out)     ; Tell C the size of the numeric arena
    (write-uint32 active-index out)     ; Tell C where to start
    
    ;; 2. Sub-Arena A: Text (160 bytes)
    (loop for msg in messages do
          (loop for i from 0 below +msg-len+ do
                (write-byte (if (< i (length msg)) (char-code (char msg i)) 0) out)))
                
    ;; 3. Sub-Arena B: Numeric Data (16 bytes)
    ;; We will initialize the first 5 slots to '0' (Pending) and the rest to '255' (Unused)
    (loop for i from 0 below +data-count+ do
          (if (< i +msg-count+)
              (write-byte 0 out)   ; Status 0 = Pending
              (write-byte 255 out))) ; Status 255 = Null/Padding
                
    ;; 4. The Footer / Sentinel (4 bytes)
    (write-uint32 +sentinel+ out)))

;; =========================================================================
;; EXECUTION
;; =========================================================================
(defparameter *task-phases*
  '("Phase 1: Boot sequence"
    "Phase 2: Establish uplink"
    "Phase 3: Synchronize data"
    "Phase 4: Deploy payload"
    "Phase 5: Terminate"))

;; Set the initial execution index to 0 (Start at the beginning)
(bake-universe "world4.bin" *task-phases* 0)
(format t "[Lisp] Single Source of Truth compiled to 'world4.bin' (v~A).~%" +version+)
(sb-ext:exit)