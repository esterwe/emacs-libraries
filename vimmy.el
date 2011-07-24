;;; vimmy.el --- do what I want in a Vimmy way

;; Author: Štěpán Němec <stepnem@gmail.com>
;; Time-stamp: "2011-06-04 23:17:53 CEST stepnem"
;; Created: 2010-10-04 21:37:03 Monday +0200
;; Keywords: emulation, vim, convenience, editing
;; Licence: Whatever Works
;; Tested-with: GNU Emacs 24

;;; Commentary:

;; This is a Vim-based Emacs UI layer that does what *I* want. Primary
;; concerns are simplicity, consistency and symbiosis with other Emacs
;; functionality, not actual Vim emulation. If you prefer the latter, and esp.
;; if you don't grok Elisp, you might be better served by Vimpulse or
;; vim-mode.

;; Corrections and constructive feedback appreciated.

;;; Code:

(require 'dotelib)                      ; (cl: `case', `lexical-let')
(require 'goto-last-change)
(require 'hippie-exp)
(require 'undo-tree)

;;;###autoload
(define-minor-mode vimmy-mode "Do what I want in a Vimmy way." nil nil nil
  :global t
  (let ((frob-hooks `(lambda (h)
                       (,(if vimmy-mode 'add-hook 'remove-hook)
                        h 'vimmy-buffer-mode))))
    (vimmy-frob-keymaps (not vimmy-mode))
    (mapc frob-hooks
          '(after-change-major-mode-hook find-file-hook fundamental-mode-hook))
    (if vimmy-mode
        (progn
          (unless (memq 'vimmy-mode-line-string global-mode-string)
            (setq global-mode-string
                  (append '("" vimmy-mode-line-string) global-mode-string)))
          (.walk-buffers 'vimmy-buffer-mode))
      (setq global-mode-string
            (delq 'vimmy-mode-line-string global-mode-string)))))

(.deflocalvar vimmy-mode-line-string nil nil t)

(defun vimmy-frob-keymaps (&optional unfrob)
  (let ((there (memq 'vimmy-mode-maps-alist emulation-mode-map-alists)))
    (if unfrob
        (when there
          (setq emulation-mode-map-alists
                (remove 'vimmy-mode-maps-alist emulation-mode-map-alists)))
      (unless there
        (push 'vimmy-mode-maps-alist emulation-mode-map-alists)))))

(defun vimmy-buffer-mode ()
  (interactive)
  (let ((modesym (cdr (assq major-mode vimmy-buffer-mode-alist))))
    (funcall (.format-symbol "vimmy-switch-to-%s" (or modesym 'normal)))))

(defvar vimmy-buffer-mode-alist
  '((Info-mode . emacs)
    (bbdb-mode . emacs)
    (bookmark-bmenu-mode . emacs)
    (browse-kill-ring-mode . emacs)
    (calc-mode . emacs)
    (calendar-mode . emacs)
    (delicious-search-mode . emacs)
    (debugger-mode . emacs)
    (desktop-menu-mode . emacs)
    (desktop-menu-blist-mode . emacs)
    (dired-mode . emacs)
    (edebug-mode . emacs)
    (emms-browser-mode . emacs)
    (emms-mark-mode . emacs)
    (emms-metaplaylist-mode . emacs)
    (emms-playlist-mode . emacs)
    (etags-select-mode . emacs)
    (fj-mode . emacs)
    (gc-issues-mode . emacs)
    (gnus-browse-mode . emacs)
    (gnus-group-mode . emacs)
    (gnus-server-mode . emacs)
    (gnus-summary-mode . emacs)
    (google-maps-static-mode . emacs)
    (ibuffer-mode . emacs)
    (magit-key-mode . emacs)
    (magit-mode . emacs)
    (org-agenda-mode . emacs)
    (proced-mode . emacs)
    (sldb-mode . emacs)
    (slime-repl-mode . emacs)
    (tetris-mode . emacs)
    (undo-tree-visualizer-mode . emacs)
    (urlview-mode . emacs)
    (w3m-mode . emacs)))

;;;; Keys
(defun vimmy-G (&optional count)
  (interactive "P")
  (if count (goto-line count) (goto-char (point-max)))
  (back-to-indentation))

(defun vimmy-gg (&optional count)
  (interactive "P")
  (if count (goto-line count) (goto-char (point-min)))
  (back-to-indentation))

(defun vimmy-0 ()
  (interactive)
  (call-interactively (if (eq last-command 'digit-argument)
                          'digit-argument
                        'beginning-of-line)))

(defun vimmy-w (count)
  (interactive "p")
  (dotimes (_ count)
    (when (zerop (skip-syntax-forward "w"))
      (skip-syntax-forward "^w-"))
    (skip-syntax-forward "-")))

(defun vimmy-b (count)
  (interactive "p")
  (dotimes (_ count)
    (when (zerop (skip-syntax-backward "w"))
      (skip-syntax-backward "^w")
      (skip-syntax-backward "w"))))

(defun vimmy-W (count)
  (interactive "p")
  (dotimes (_ count)
    (skip-syntax-forward "^-")
    (skip-syntax-forward "-")))

(defun vimmy-B (count)
  (interactive "p")
  (dotimes (_ count)
    (skip-syntax-backward "-")
    (skip-syntax-backward "^-")))

(defun vimmy-e (count)
  (interactive "p")
  (forward-word count)
  (backward-char))

(defun vimmy-E (count)
  (interactive "p")
  (skip-syntax-forward "^-")
  (backward-char))

(defun vimmy-f (count)
  (interactive "p")
  (.with-executing-kbd-macro-nil
    (let ((c (char-to-string (read-char))))
      (when (looking-at c) (forward-char))
      (search-forward c nil nil count)
      (forward-char -1))))

(defun vimmy-t (count)
  (interactive "p")
  (vimmy-f count)
  (forward-char -1))

(defun vimmy-F (count)
  (interactive "p")
  (.with-executing-kbd-macro-nil
    (let ((c (read-char)))
      (search-backward (char-to-string c) nil nil count))))

(defun vimmy-T (count)
  (interactive "p")
  (vimmy-F count)
  (forward-char))

(defun vimmy-* ()
  (interactive)
  (vimmy-fake-isearch t))

(defun vimmy-\# ()
  (interactive)
  (vimmy-fake-isearch))

(defun vimmy-fake-isearch (&optional fwd)
  (let ((sym (symbol-at-point)))
    (when sym
      (let ((str (symbol-name sym)))
        (isearch-resume str nil nil fwd str nil)))))

(defun vimmy-K (&optional info)
  (interactive "P")
  (if info
      (info (.complete-with-default
             "Info node" 'Info-read-node-name-1 nil
             (let ((s (thing-at-point 'symbol)))
               (when s (concat "(" s ")")))))
    (call-interactively 'man)))

(defun vimmy-I ()
  (interactive)
  (beginning-of-line)
  (vimmy-start-insert))

(defun vimmy-a (count)
  (interactive "p")
  (unless (eolp) (forward-char))
  (vimmy-start-insert count))

(defun vimmy-A (count)
  (interactive "p")
  (end-of-line)
  (vimmy-start-insert count))

(defun vimmy-normal-o (&optional count)
  (interactive "P")
  (end-of-line)
  (vimmy-start-insert count)
  (newline-and-indent))

(defun vimmy-normal-O (&optional count)
  (interactive "P")
  (beginning-of-line)
  (vimmy-start-insert count)
  (open-line 1))

(defun vimmy-J (count)
  (interactive "p")
  (vimmy-repeatable ((count count))
    (dotimes (_ count)
      (delete-indentation t))))

(.deflocalvar vimmy-last-repeatable nil nil t)
(defvar vimmy-repeat-history (make-ring 10))
(defun vimmy-normal-\. (&optional count)
  (interactive "P")
  (let ((vimmy-repeating t))
    (case vimmy-last-repeatable
      (insert (dotimes (_ (or count vimmy-insert-count 1))
                (insert vimmy-last-insert-text)))
      (delete (vimmy-d vimmy-last-count))
      (change (vimmy-c vimmy-last-count))
      (t (if (> (ring-length vimmy-repeat-history) 0)
             (let ((cmd (ring-ref vimmy-repeat-history 0)))
               (dotimes (_ (or count (car cmd) 1))
                 (funcall (cdr cmd))))
           (call-interactively 'repeat)
           ;; (error "Dunno what to repeat")
           )))))

(defmacro vimmy-repeatable (bindings &rest body)
  (declare (debug t) (indent 1))
  `(progn (when (called-interactively-p 'interactive)
            (setq vimmy-last-repeatable nil)
            (lexical-let ,bindings
              (ring-insert vimmy-repeat-history
                           (cons current-prefix-arg (lambda () ,@body)))))
          ,@body))

(defun vimmy-normal-r (count)
  (interactive "p")
  (let ((c (read-char)))
    (vimmy-repeatable ((c c) (count 1))
      (delete-char count)
      (insert (make-string count c)))))

(defun vimmy-~ (count)
  (interactive "p")
  (vimmy-repeatable nil
    (vimmy-apply-to-text '.invert-case-region)))

(defun vimmy-normal-~ (count)
  (interactive "p")
  (vimmy-repeatable nil
    (.invert-case-region (point)
                         (save-excursion (forward-char count) (point)))
    (forward-char)))

(defun vimmy-\" ()
  (interactive)
  (setq vimmy-current-register (read-char)))

(.deflocalvar vimmy-last-motion-type nil nil t)
(defun vimmy-normal-p (count)
  (interactive "p")
  (vimmy-repeatable ((count count))
    (save-excursion
      (dotimes (_ count)
        (case vimmy-last-motion-type
          (line (forward-line))
          (char (forward-char)))
        (insert-for-yank (vimmy-register-get vimmy-current-register))
        (indent-according-to-mode)))))

(defun vimmy-normal-P (count)
  (interactive "p")
  (vimmy-repeatable ((count count))
    (dotimes (_ count)
      (insert-for-yank (vimmy-register-get vimmy-current-register))
      (indent-according-to-mode))))

(defun vimmy-c (count)
  (interactive "p")
  (setq vimmy-current-command "c"
        vimmy-last-count count
        vimmy-last-repeatable 'change)
  (vimmy-d count)
  (vimmy-start-insert))

(defun vimmy-C ()
  (interactive)
  (vimmy-D)
  (vimmy-start-insert))

(defun vimmy-d (count)
  (interactive "p")
  (unless (eq this-command 'vimmy-c)
    (setq vimmy-current-command "d"
          vimmy-last-count count
          vimmy-last-repeatable 'delete))
  (vimmy-with-motion-or-region
    (vimmy-register-set
     (if vimmy-visual-block-mode
         (mapconcat 'identity (extract-rectangle beg end) "\n")
       (buffer-substring beg end)))
    (funcall (if vimmy-visual-block-mode 'delete-rectangle 'delete-region)
             beg end))
  (vimmy-switch-to-normal))

(defun vimmy-D ()
  (interactive)
  (vimmy-repeatable nil
    (let ((beg (point)) (end (line-end-position)))
      (vimmy-register-set (buffer-substring beg end))
      (delete-region beg end))))

(defun vimmy-x (count)
  (interactive "p")
  (vimmy-repeatable ((count count))
    (vimmy-register-set (buffer-substring (point) (+ (point) count)))
    (delete-char count))
  (setq vimmy-last-motion-type 'char))

(defun vimmy-X (count)
  (interactive "p")
  (vimmy-repeatable ((count count))
    (vimmy-register-set (buffer-substring (point) (- (point) count)))
    (delete-char (- count)))
  (setq vimmy-last-motion-type 'char))

(defun vimmy-y (count)
  (interactive "p")
  (setq vimmy-current-command "y")
  (vimmy-with-motion-or-region
    (vimmy-register-set
     (if vimmy-visual-block-mode
         (mapconcat 'identity (extract-rectangle beg end) "\n")
       (buffer-substring beg end))))
  (vimmy-switch-to-normal))

(defun vimmy-Y ()
  (interactive)
  (vimmy-repeatable nil
    (vimmy-register-set (buffer-substring (point) (line-end-position)))))

;;;; Modes
(defvar vimmy-mode-string-alist
  '((emacs . "<E> ")
    (operator . "<O> ")
    (normal . "<N> ")
    (insert . "<I> ")
    (visual-char . "<Vc> ")
    (visual-line . "<Vl> ")
    (visual-block . "<Vb> ")))

(defvar vimmy-mode-cursor-alist
  '((emacs . t)
    (operator . hbar)
    (normal . t)
    (insert . bar)
    (visual-char . t)
    (visual-line . t)
    (visual-block . t)))

(.deflocalvar vimmy-current-mode 'normal nil t)

(defsubst vimmy-mode-symbol (mode) (.format-symbol "vimmy-%s-mode" mode))

(defmacro vimmy-define-mode (mode doc &rest kwargs)
  (declare (debug t) (indent defun))
  (let* ((modesym (vimmy-mode-symbol mode))
         (mapsym (.format-symbol "%s-map" modesym))
         (switchsym (.format-symbol "vimmy-switch-to-%s" mode))
         (kwarg (apply-partially 'plist-get kwargs))
         (keys (funcall kwarg :keys))
         (on (funcall kwarg :on))
         (off (funcall kwarg :off)))
    `(progn
       (make-variable-buffer-local (defvar ,modesym nil))
       (defun ,modesym (&optional arg)
         ,doc
         (interactive (list (or current-prefix-arg 'toggle)))
         (setq ,modesym (if (eq arg 'toggle) (not ,modesym)
                          (> (prefix-numeric-value arg) 0)))
         (if ,modesym
             (progn
               (setq vimmy-current-mode ',mode
                     cursor-type (assoc-default ',mode vimmy-mode-cursor-alist)
                     vimmy-mode-line-string (assoc-default
                                             ',mode vimmy-mode-string-alist))
               ,on)
           ,off)
         (force-mode-line-update)
         ,modesym)
       (defun ,switchsym ()
         (interactive)
         (when vimmy-current-mode
           (funcall (vimmy-mode-symbol vimmy-current-mode) -1))
         (,modesym 1))
       (defvar ,mapsym (make-sparse-keymap))
       ,@(when keys
           `((mapc (apply-partially 'apply 'define-key ,mapsym) ,keys))))))

;;; Emacs mode
(vimmy-define-mode emacs "Vimmy mode that is like Emacs."
  :keys '(("\C-z" vimmy-switch-to-normal)))

;;; Window map
(.defprefix vimmy-window-prefix '(("\C-w" other-window)
                                  ("w" other-window)
                                  ("p" .goto-mru-window)
                                  ("c" delete-window)
                                  ("o" delete-other-windows)
                                  ("s" split-window-vertically)
                                  ("v" split-window-horizontally)
                                  ("h" windmove-left)
                                  ("j" windmove-down)
                                  ("k" windmove-up)
                                  ("l" windmove-right)
                                  ("f" ctl-x-5-prefix)))

;;; Normal mode
(vimmy-define-mode normal "Vimmy Normal mode."
  :keys '(("\C-z" vimmy-switch-to-emacs)
          ("v" vimmy-normal-v)
          ("V" vimmy-normal-V)
          ("\C-v" vimmy-normal-C-v)

          ("k" previous-line)
          ("j" next-line)
          ("h" backward-char)
          ("l" forward-char)
          ("^" back-to-indentation)
          ("$" move-end-of-line)

          (" " scroll-up-command)
          ("\C-?" scroll-down-command)
          ([backspace] scroll-down-command)

          ("G" vimmy-G)
          ("gg" vimmy-gg)

          ("w" vimmy-w)
          ("W" vimmy-W)
          ("e" vimmy-e)
          ("E" vimmy-E)
          ("b" vimmy-b)
          ("B" vimmy-B)
          ;; ("ge" vimmy-ge)
          ;; ("gE" vimmy-gE)

          ("0" vimmy-0)
          ("1" digit-argument)
          ("2" digit-argument)
          ("3" digit-argument)
          ("4" digit-argument)
          ("5" digit-argument)
          ("6" digit-argument)
          ("7" digit-argument)
          ("8" digit-argument)
          ("9" digit-argument)

          ("u" undo)
          ("\C-r" undo-tree-redo)

          ("f" vimmy-f)
          ("F" vimmy-F)
          ("t" vimmy-t)
          ("T" vimmy-T)
          ("*" vimmy-*)
          ("#" vimmy-\#)

          ("J" vimmy-J)

          ("i" vimmy-start-insert)
          ("I" vimmy-I)
          ("a" vimmy-a)
          ("A" vimmy-A)
          ("o" vimmy-normal-o)
          ("O" vimmy-normal-O)

          ("." vimmy-normal-\.)

          ("g;" goto-last-change)
          ("g," goto-last-change-reverse)
          ("ga" what-cursor-position)
          ("gi" vimmy-gi)
          ("gv" vimmy-gv)
          ("go" goto-char)

          ("r" vimmy-normal-r)

          ("c" vimmy-c)
          ("C" vimmy-C)
          ("d" vimmy-d)
          ("D" vimmy-D)
          ("y" vimmy-y)
          ("Y" vimmy-Y)
          ("x" vimmy-x)
          ("X" vimmy-X)
          ("p" vimmy-normal-p)
          ("P" vimmy-normal-P)

          ("~" vimmy-normal-~)
          ("g~" vimmy-~)

          ("\"" vimmy-\")

          ("m" vimmy-m)
          ("'" vimmy-\')
          ("`" vimmy-\`)

          ("K" vimmy-K)
          ;; ("\C-t" pop-tag-mark)
          ("\C-w" vimmy-window-prefix)))

;;; Operator mode
(vimmy-define-mode operator "Vimmy Operator mode.")
(set-keymap-parent vimmy-operator-mode-map vimmy-normal-mode-map)

(defvar vimmy-operators nil)
(defmacro vimmy-defop (key &rest body)
  (declare (debug t) (indent 1))
  (let ((cmd (.format-symbol "vimmy-op-%s" key))
        (viscmd (.format-symbol "vimmy-visual-op-%s" key)))
    `(progn
       (defun ,cmd (&optional count)
         (interactive "p")
         ,@body)
       (defun ,viscmd (&optional count)
         (interactive "p")
         (let ((bounds (progn ,@body)))
           (goto-char (car bounds))
           (set-mark (point))
           (goto-char (cdr bounds))))
       (add-to-list 'vimmy-operators ,key)
       (define-key vimmy-operator-mode-map ,key ',cmd)
       (define-key vimmy-visual-common-map ,key ',viscmd))))

(defvar vimmy-current-command nil)
(defvar vimmy-last-count nil)
(defvar vimmy-last-motion nil)
(defvar vimmy-repeating nil)
(defun vimmy-read-motion ()
  (vimmy-operator-mode 1)
  (unwind-protect
      (let ((mot (setq vimmy-last-motion (read-key-sequence nil))))
        (when (member mot vimmy-operators)
          (setq mot (funcall (.format-symbol "vimmy-op-%s" mot))))
        mot)
    (vimmy-operator-mode -1)))

(defmacro vimmy-with-motion (&rest body)
  (declare (debug t) (indent 0))
  (.with-made-symbols (count mot line)
    `(let* ((,mot (if vimmy-repeating vimmy-last-motion (vimmy-read-motion)))
            (,line (equal ,mot vimmy-current-command))
            (,count (if current-prefix-arg
                        (prefix-numeric-value current-prefix-arg)
                      (or vimmy-last-count 1)))
            (beg (if (consp ,mot)
                     (car ,mot)
                   (if ,line (line-beginning-position) (point))))
            (end (if (consp ,mot)
                     (cdr ,mot)
                   (save-excursion
                     (if ,line
                         (progn (forward-line (1- ,count))
                                (1+ (line-end-position)))
                       (dotimes (_ ,count)
                         (command-execute ,mot))
                       (point))))))
       (setq vimmy-last-motion-type (if ,line 'line nil))
       ,@body)))

(defmacro vimmy-with-motion-or-region (&rest body)
  (declare (debug t) (indent 0))
  (let ((b+e (make-symbol "b+e")))
    `(if vimmy-normal-mode
         (vimmy-with-motion ,@body)
       (let* ((,b+e (vimmy-visual-region-bounds))
              (beg (car ,b+e))
              (end (cdr ,b+e)))
         ,@body))))

(autoload 'apply-on-rectangle "rect")
(defun vimmy-apply-to-text (fun)
  (interactive "aFunction: ")
  (vimmy-with-motion-or-region
    (if vimmy-visual-block-mode
        (apply-on-rectangle
         (lambda (s e)
           (funcall fun
                    (save-excursion (move-to-column s) (point))
                    (save-excursion (move-to-column e) (point))))
         beg end)
      (funcall fun beg end))))

;;; Insert mode
(vimmy-define-mode insert "Vimmy Insert mode."
  :keys '(("\e" vimmy-stop-insert)
          ("\C-p" dabbrev-expand)
          ("\C-n" vimmy-expand-after)
          ("\C-x\C-l" vimmy-expand-line)
          ("\C-e" .copy-from-below)
          ("\C-y" .copy-from-above)))

(.deflocalvar vimmy-insert-count nil nil t)
(.deflocalvar vimmy-last-insert-start nil nil t)
(.deflocalvar vimmy-last-insert-text nil nil t)

(defun vimmy-start-insert (&optional count)
  (interactive "P")
  (setq vimmy-insert-count (prefix-numeric-value count))
  (vimmy-switch-to-insert)
  (setq vimmy-last-insert-start (point-marker)))

(defun vimmy-stop-insert ()
  (interactive)
  (vimmy-switch-to-normal)
  (setq vimmy-last-insert-text (buffer-substring vimmy-last-insert-start
                                                 (point))
        vimmy-last-repeatable 'insert)
  (when vimmy-insert-count
    (dotimes (_ (1- vimmy-insert-count))
      (insert vimmy-last-insert-text)))
  (vimmy-mark-set ?^ (point-marker)))

(defun vimmy-gi ()
  (interactive)
  (vimmy-goto-mark ?^ t)
  (vimmy-start-insert))

(defun vimmy-expand-after ()
  (interactive)
  (dabbrev-expand -1))

(defun vimmy-expand-line (&optional arg)
  (interactive "P")
  (let ((hippie-expand-try-functions-list
         '(try-expand-line try-expand-line-all-buffers)))
    (hippie-expand arg)))

;;; Visual mode
(defvar vimmy-visual-common-map (make-sparse-keymap) "Keymap inherited by all Visual mode types.")
(set-keymap-parent vimmy-visual-common-map vimmy-operator-mode-map)
(vimmy-define-mode visual-char "Vimmy characterwise Visual mode."
  :keys '(("v" vimmy-switch-to-normal)
          ("~" vimmy-~))
  :off (vimmy-visual-cleanup))

(set-keymap-parent vimmy-visual-char-mode-map vimmy-visual-common-map)

(vimmy-define-mode visual-line "Vimmy linewise Visual mode."
  :keys '(("V" vimmy-switch-to-normal))
  :off (vimmy-visual-cleanup))

(vimmy-define-mode visual-block "Vimmy blockwise Visual mode."
  :keys '(("\C-v" vimmy-switch-to-normal))
  :off (vimmy-visual-cleanup))

(defun vimmy-visual-off-maybe (&rest ignore)
  (when (or vimmy-visual-char-mode
            vimmy-visual-line-mode
            vimmy-visual-block-mode)
    (vimmy-switch-to-normal)))

(defun vimmy-visual-cleanup ()
  ;; FIXME how wasteful is this?
  (vimmy-mark-set ?< (set-marker (make-marker) (region-beginning)))
  (vimmy-mark-set ?> (set-marker (make-marker) (region-end)))
  ;; (setq vimmy-last-visual-region (cons (region-beginning) (region-end)))
  (remove-hook 'after-change-functions 'vimmy-visual-off-maybe t)
  (deactivate-mark)
  ;; (setq mark-active nil)
  )

(mapc (lambda (s)
        (let ((m (symbol-value (.format-symbol "vimmy-visual-%s-mode-map" s))))
          (set-keymap-parent m vimmy-visual-char-mode-map)
          (define-key m "v" 'vimmy-switch-to-visual-char)))
      '(line block))

(defun vimmy-visual-region-bounds ()
  (let ((beg (region-beginning)) (end (region-end)))
    (if vimmy-visual-line-mode
        (cons (save-excursion (goto-char beg)
                              (line-beginning-position))
              (save-excursion (goto-char end)
                              (1+ (line-end-position))))
      (cons beg end))))

(.deflocalvar vimmy-visual-last-type nil nil t)
(defun vimmy-visual (type &optional dont-set-mark)
  (when (eq type 'line) (beginning-of-line))
  (unless dont-set-mark (set-mark-command nil))
  (unless transient-mark-mode
    (setq transient-mark-mode 'lambda))
  (funcall (.format-symbol "vimmy-switch-to-visual-%s" type))
  (add-hook 'after-change-functions 'vimmy-visual-off-maybe nil t)
  (setq vimmy-visual-last-type type))

(defun vimmy-normal-v ()
  (interactive)
  (vimmy-visual 'char))

(defun vimmy-normal-V ()
  (interactive)
  (vimmy-visual 'line))

(defun vimmy-normal-C-v ()
  (interactive)
  (vimmy-visual 'block))

(defun vimmy-gv ()
  (interactive)
  (goto-char (cdr (vimmy-mark-get ?<)))
  (set-mark-command nil)
  (goto-char (cdr (vimmy-mark-get ?>)))
  (vimmy-visual vimmy-visual-last-type t))

(vimmy-defop "ae" (bounds-of-thing-at-point 'sexp))
(vimmy-defop "au" (bounds-of-thing-at-point 'url))

(defun vimmy-define-mode-maps-alist ()
  (eval
   `(defvar vimmy-mode-maps-alist
      ',(mapcar (lambda (m)
                  `(,(vimmy-mode-symbol m)
                    . ,(symbol-value (.format-symbol "vimmy-%s-mode-map" m))))
                '(emacs operator normal insert visual-char visual-line visual-block)))))

(vimmy-define-mode-maps-alist)

;;;; Marks
(defvar vimmy-global-marks-alist nil)
(.deflocalvar vimmy-local-marks-alist nil nil t)

(defun vimmy-mark-set (char value &optional global)
  (let* ((marks-alist (if global 'vimmy-global-marks-alist
                        'vimmy-local-marks-alist))
         (mark (assq char (symbol-value marks-alist)))
         (value (if value (if (consp value) value
                            (cons buffer-file-name value))
                  (cons buffer-file-name (point-marker)))))
    (if mark (setcdr mark value)
      (push (cons char value) (symbol-value marks-alist)))
    (add-hook 'kill-buffer-hook 'vimmy-mark-swap-out nil t)
    value))

(defun vimmy-mark-swap-out ()
  "Cf. `register-swap-out'."
  (when buffer-file-name
    (dolist (elt vimmy-global-marks-alist)
      (let ((marker (cddr elt)))
        (and (markerp marker)
             (eq (marker-buffer marker) (current-buffer))
             (setcdr (cdr elt) (marker-position marker)))))))

(defun vimmy-mark-get (char)
  (or (cdr (assq char (if (and (<= ?A char) (<= char ?Z))
                          vimmy-global-marks-alist
                        vimmy-local-marks-alist)))
      (error "No such mark: %c" char)))

(defun vimmy-goto-mark (c &optional exact)
  (let* ((fn+pos (vimmy-mark-get c))
         (fn (car fn+pos))
         (pos (cdr fn+pos)))
    (if (markerp pos)
        (unless (eq (marker-buffer pos) (current-buffer))
          (switch-to-buffer (marker-buffer pos)))
      (unless (equal buffer-file-name fn)
        (or (and (or (find-buffer-visiting fn)
                     (y-or-n-p (format "Visit file %s again? " fn)))
                 (find-file fn))
            (message "Kthx"))))
    (goto-char pos)
    (unless exact (back-to-indentation))))

(defun vimmy-m ()
  (interactive)
  (let ((c (read-char)))
    (vimmy-mark-set c nil (and (<= ?A c) (<= c ?Z)))))

(defun vimmy-read-mark ()
  (read-char-exclusive
   (propertize
    (mapconcat
     'string
     (apply 'append
            (mapcar (& 'mapcar 'car)
                    (list vimmy-global-marks-alist vimmy-local-marks-alist)))
     "")
    'face 'minibuffer-prompt)))
;; ` and ' are deliberately swapped WRT Vim
(defun vimmy-\` (arg)
  (interactive "P")
  (vimmy-goto-mark (vimmy-read-mark)))

(defun vimmy-\' (arg)
  (interactive "P")
  (vimmy-goto-mark (vimmy-read-mark) t))

;;;; Registers
(defvar vimmy-register-alist nil)
(defvar vimmy-current-register ?-)
(defsubst vimmy-register (reg) (assq reg vimmy-register-alist))

(defun vimmy-register-get (&optional reg default)
  (prog1 (or (cdr (vimmy-register (or reg vimmy-current-register))) default)
    (setq vimmy-current-register ?-)))

(defun vimmy-register-set (val &optional reg)
  (let* ((reg (or reg vimmy-current-register))
         (r (vimmy-register reg)))
    (if r (setcdr r val) (push (cons reg val) vimmy-register-alist))
    (setq vimmy-current-register ?-)))

(defun vimmy-reload ()
  (interactive)
  (unload-feature 'vimmy t)
  (require 'vimmy)
  (vimmy-mode 1))

(provide 'vimmy)
;;; vimmy.el ends here

(defun vimmy-test ()
  (interactive)
  (start-process "vimmy-test" nil "emacs" "-Q" "-r" "-l" "~/vimmy-test.el"))

(ignore-errors
  (let ((keyword-regex (concat "(\\("
                               (regexp-opt '("vimmy-define-mode"
                                             "vimmy-defop"
                                             "vimmy-repeatable"
                                             "vimmy-with-motion"
                                             "vimmy-with-motion-or-region"))
                               "\\)\\>")))
    (font-lock-add-keywords 'emacs-lisp-mode `((,keyword-regex . 1)))))
