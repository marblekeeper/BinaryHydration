;; emit.lisp
;; Bakes a fixed-size 2D string array and a verification sentinel.

;; =========================================================================
;; THE PHYSICAL SPEC (Mirrors the C Struct)
;; =========================================================================
(defconstant +msg-count+ 5)
(defconstant +msg-len+ 32)
(defconstant +sentinel+ #xDEADBEEF)

;; =========================================================================
;; STATIC ANALYZER PASS
;; =========================================================================
(defun verify-geometry (messages)
  "Verifies that the Lisp data matches the C memory layout precisely."
  (format t "[Analyzer] Running geometric verification pass...~%")
  
  ;; Rule 1: Must be exactly the expected number of messages.
  ;; Otherwise, the sentinel will shift into the wrong memory address.
  (let ((actual-count (length messages)))
    (when (/= actual-count +msg-count+)
      (error "[FATAL] Geometry Mismatch: C expects ~A messages, but Lisp provided ~A." 
             +msg-count+ actual-count)))
  
  ;; Rule 2: Each message must fit within the fixed buffer.
  ;; We enforce strictly less than +msg-len+ to guarantee a C null-terminator.
  (loop for msg in messages
        for i from 0
        do (let ((len (length msg)))
             (when (>= len +msg-len+)
               (error "[FATAL] Buffer Overflow Prevented: Message [~A] is ~A bytes. Maximum allowed is ~A bytes (saving 1 for null-terminator)." 
                      i len (1- +msg-len+)))))
                      
  (format t "[Analyzer] Geometry verified. Data aligns with C specification.~%"))

;; =========================================================================
;; THE BAKE
;; =========================================================================
(defun write-uint32 (val stream)
  "Writes a 32-bit integer in Little-Endian format."
  (write-byte (ldb (byte 8 0)  val) stream)
  (write-byte (ldb (byte 8 8)  val) stream)
  (write-byte (ldb (byte 8 16) val) stream)
  (write-byte (ldb (byte 8 24) val) stream))

(defun bake-messages (filename messages)
  ;; 1. Run the static analyzer pass first
  (verify-geometry messages)
  
  ;; 2. Execute the bake
  (with-open-file (out filename 
                       :direction :output 
                       :element-type '(unsigned-byte 8) 
                       :if-exists :supersede)
    
    ;; Write the Array of Strings
    (loop for msg in messages do
          (loop for i from 0 below +msg-len+ do
                (write-byte (if (< i (length msg)) 
                                (char-code (char msg i)) 
                                0) ; Null byte padding for C
                            out)))
                            
    ;; Write the Sentinel Value at the very end
    (write-uint32 +sentinel+ out)))

;; =========================================================================
;; EXECUTION
;; =========================================================================
(defparameter *my-messages*
  '("System initializing..."
    "Hydration protocol active."
    "Zero parsing required."
    "Sentinel check standby."
    "All systems nominal."))

(bake-messages "world.bin" *my-messages*)
(format t "[Lisp] Message slab 'world.bin' baked with sentinel.~%")
(sb-ext:exit)