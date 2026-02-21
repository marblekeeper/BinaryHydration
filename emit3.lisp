;; emit3.lisp
;; Bakes a Magic Header, Version, active offset, array, and Sentinel.

(defconstant +magic-number+ #x5A45524F) ; "ZERO" in hex
(defconstant +version+ 3)
(defconstant +msg-count+ 5)
(defconstant +msg-len+ 32)
(defconstant +sentinel+ #xDEADBEEF)

;; =========================================================================
;; STATIC ANALYZER PASS
;; =========================================================================
(defun verify-geometry (messages active-index)
  (format t "[Analyzer] Verifying v~A geometry...~%" +version+)
  (when (/= (length messages) +msg-count+)
    (error "[FATAL] C expects ~A messages." +msg-count+))
  (when (or (< active-index 0) (>= active-index +msg-count+))
    (error "[FATAL] Active index ~A out of bounds." active-index))
  (loop for msg in messages for i from 0 do
        (when (>= (length msg) +msg-len+)
          (error "[FATAL] Message ~A overflows buffer." i)))
  (format t "[Analyzer] Geometry verified. Data aligns with C spec v~A.~%" +version+))

;; =========================================================================
;; THE BAKE
;; =========================================================================
(defun write-uint32 (val stream)
  (write-byte (ldb (byte 8 0)  val) stream)
  (write-byte (ldb (byte 8 8)  val) stream)
  (write-byte (ldb (byte 8 16) val) stream)
  (write-byte (ldb (byte 8 24) val) stream))

(defun bake-state (filename messages active-index)
  (verify-geometry messages active-index)
  
  (with-open-file (out filename :direction :output :element-type '(unsigned-byte 8) :if-exists :supersede)
    
    ;; 1. The Header (8 bytes)
    (write-uint32 +magic-number+ out)
    (write-uint32 +version+ out)
    
    ;; 2. The Active Offset (4 bytes)
    ;; Offset = 4(magic) + 4(version) + 4(offset itself) + (index * 32)
    ;; Base offset to the array is now 12 bytes.
    (let ((active-offset (+ 12 (* active-index +msg-len+))))
      (format t "[Lisp] Active offset calculated at ~A bytes from base.~%" active-offset)
      (write-uint32 active-offset out))
    
    ;; 3. The Data (160 bytes)
    (loop for msg in messages do
          (loop for i from 0 below +msg-len+ do
                (write-byte (if (< i (length msg)) (char-code (char msg i)) 0) out)))
                
    ;; 4. The Footer / Sentinel (4 bytes)
    (write-uint32 +sentinel+ out)))

;; =========================================================================
;; EXECUTION
;; =========================================================================
(defparameter *task-phases*
  '("Phase 1: Boot sequence"
    "Phase 2: Establish uplink"
    "Phase 3: Synchronize data"     ;; <--- Suspending at Phase 3 again
    "Phase 4: Deploy payload"
    "Phase 5: Terminate"))

(bake-state "world3.bin" *task-phases* 2)
(format t "[Lisp] Process safely suspended to 'world3.bin' (v~A).~%" +version+)
(sb-ext:exit)