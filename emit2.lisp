;; emit2.lisp
;; Bakes a state machine array, the active execution offset, and a sentinel.

(defconstant +msg-count+ 5)
(defconstant +msg-len+ 32)
(defconstant +sentinel+ #xDEADBEEF)

;; =========================================================================
;; STATIC ANALYZER PASS
;; =========================================================================
(defun verify-geometry (messages active-index)
  (format t "[Analyzer] Verifying state geometry...~%")
  
  (let ((actual-count (length messages)))
    (when (/= actual-count +msg-count+)
      (error "[FATAL] C expects ~A messages, got ~A." +msg-count+ actual-count)))
      
  (when (or (< active-index 0) (>= active-index +msg-count+))
    (error "[FATAL] Active index ~A is out of bounds. Cannot bake an invalid offset." active-index))
    
  (loop for msg in messages for i from 0 do
        (when (>= (length msg) +msg-len+)
          (error "[FATAL] Message ~A overflows buffer." i)))
          
  (format t "[Analyzer] Geometry verified. Data aligns with C specification.~%"))

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
  
  (with-open-file (out filename 
                       :direction :output 
                       :element-type '(unsigned-byte 8) 
                       :if-exists :supersede)
    
    ;; 1. Write the Active Offset (4 bytes)
    ;; The physical distance to the active message from the start of the struct is: 
    ;; 4 bytes (for this offset itself) + (active-index * 32 bytes)
    (let ((active-offset (+ 4 (* active-index +msg-len+))))
      (format t "[Lisp] Saving active state offset at ~A bytes from base.~%" active-offset)
      (write-uint32 active-offset out))
    
    ;; 2. Write the Array of Strings (160 bytes)
    (loop for msg in messages do
          (loop for i from 0 below +msg-len+ do
                (write-byte (if (< i (length msg)) 
                                (char-code (char msg i)) 
                                0) ; Null byte padding for C
                            out)))
                
    ;; 3. Write the Sentinel (4 bytes)
    (write-uint32 +sentinel+ out)))

;; =========================================================================
;; EXECUTION: HALTING MID-PROCESS
;; =========================================================================
(defparameter *task-phases*
  '("Phase 1: Boot sequence"
    "Phase 2: Establish uplink"
    "Phase 3: Synchronize data"     ;; <--- We want to halt and resume here
    "Phase 4: Deploy payload"
    "Phase 5: Terminate"))

;; We tell Lisp that index 2 is the active state.
(bake-state "world.bin" *task-phases* 2)
(format t "[Lisp] Process safely suspended to 'world.bin'.~%")
(sb-ext:exit)