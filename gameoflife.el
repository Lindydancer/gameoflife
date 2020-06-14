;;; gameoflife.el --- Screensaver running Conway's Game of Life

;; Copyright (C) 2017, 2020  Anders Lindgren

;; Author: Anders Lindgren
;; Keywords: games
;; Version: 0.0.2
;; Created: 2017-11-15
;; URL: https://github.com/Lindydancer/gameoflife

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Run Conway's Game of Life, in all windows, using the original
;; window content as seed.  In addition, when performing the
;; animation, the original characters and the colors they have, are
;; retained, resulting is a much more living result than when simply
;; using, say, stars.
;;
;; By "seed", it means that the original content of the windows are
;; seen as dots in the plane.  All non-blank characters are seen as
;; live dots.
;;
;; The Game of Life animation can be started as a screensaver, so that
;; it starts automatically when Emacs has been idle for a while.  By
;; default, it stops after 1000 generations.
;;
;; Screenshot:
;;
;; ![See doc/GameOfLifeDemo.gif for screenshot](doc/GameOfLifeDemo.gif)

;; Usage:
;;
;; `gameoflife-animate' -- Start the Game of Life animation.
;;
;; `gameoflife-screensaver-mode' -- Run as a screensaver.  The
;; animation is started when Emacs has been idle for a while.

;; About Conway's Game of Life:
;;
;; Conway's Game of Life is a simple simulation, originally developed
;; in 1970, taking place in a two-dimentional grid -- think of it as
;; an infinite chess board.
;;
;; A square can either be dead or alive.  In each step in the
;; simulation, the following rule applies:
;;
;; - A live square stays alive only if it has two or three neighbours.
;;
;; - A dead square is resurrected if it has exactly three neighburs.

;; Personal reflection:
;;
;; I have noticed that sparse programming languages with a lot of
;; highlighting, like C and C++, produde the most beautiful
;; animations.  More dense programming languages, like elisp, tend to
;; "kill" many squares in the first generation, making them less
;; suited for Game of Life seeds.

;;; Code:

(defvar gameoflife-animation-speed 0.25
  "The delay, in seconds, between gameoflife generations when animating.")


(defun gameoflife-nonspace-points-on-line ()
  "Return list of non-space points on line.

Each entry corresponds to a column, with an extra fictitious
column to left.  Each entry is the position of the character or
nil for spaces and tabs.

Example:

' x<TAB>y'  => (nil nil 2 nil nil nil nil nil nil 4)"
  (save-excursion
    (let ((res '()))
      (while (not (eolp))
        (let ((ch (char-after)))
          (cond ((eq ch ?\s)
                 (forward-char)
                 (push nil res))
                ((eq ch ?\t)
                 (let ((column (current-column)))
                   (forward-char)
                   (while (< column (current-column))
                     (setq column (+ column 1))
                     (push nil res))))
                (t
                 (push (point) res)
                 (forward-char)))))
      ;; Drop spaces at the end of the line.
      (while (and res
                  (null (nth 0 res)))
        (pop res))
      ;; Add an extra entry to represent a space in a fictitious
      ;; column to the left of the first column.
      (cons nil (nreverse res)))))


(defun gameoflife-nonspace-points-on-next-line ()
  "Return list of non-space points on next line.

See `gameoflife-nonspace-points-on-line' for details."
  (save-excursion
    (forward-line)
    (if (eobp)
        '()
      (gameoflife-nonspace-points-on-line))))


(defun gameoflife-buffer (&optional from to tmpbuf)
  "Convert current buffer to next game of life generation into TMPBUF.

Convert from FROM to TO.  When FROM and TO are nil use the start
and end of the buffer, respectively.

Return generated buffer."
  (interactive)
  (unless tmpbuf
    (setq tmpbuf (get-buffer-create "*GameOfLifeTemp*")))
  (unless from
    (setq from (point-min)))
  (unless to
    (setq to (point-max)))
  (with-current-buffer tmpbuf
    (set (make-local-variable 'truncate-lines) t)
    (setq cursor-type nil)
    (erase-buffer))
  (save-excursion
    (goto-char from)
    (beginning-of-line)
    (let ((prev-line '())
          (curr-line (gameoflife-nonspace-points-on-line))
          (next-line (gameoflife-nonspace-points-on-next-line)))
      (while
          (progn
            ;; Loop over the element on each line.
            (let ((rest-prev-line prev-line)
                  (rest-curr-line curr-line)
                  (rest-next-line next-line))
              (while (or rest-prev-line
                         rest-curr-line
                         rest-next-line)
                ;; Point or nil for LINE-COLUMN
                (let ((pp (nth 0 rest-prev-line))
                      (cp (nth 0 rest-curr-line))
                      (np (nth 0 rest-next-line))
                      (pc (nth 1 rest-prev-line))
                      (cc (nth 1 rest-curr-line))
                      (nc (nth 1 rest-next-line))
                      (pn (nth 2 rest-prev-line))
                      (cn (nth 2 rest-curr-line))
                      (nn (nth 2 rest-next-line)))
                  (let ((neighbours (+ (if pp 1 0)
                                       (if cp 1 0)
                                       (if np 1 0)
                                       (if pc 1 0)
                                       ;; Current cell (cc) isn't a neighbour.
                                       (if nc 1 0)
                                       (if pn 1 0)
                                       (if cn 1 0)
                                       (if nn 1 0))))
                    (let ((str
                           (cond ((and cc
                                       (or (eq neighbours 2)
                                           (eq neighbours 3)))
                                  ;; The cell remains alive.
                                  (buffer-substring cc (+ cc 1)))
                                 ((eq neighbours 3)
                                  ;; A new cell is born. Copy a character
                                  ;; from one of the neighbours.
                                  (let ((p (or pp pc pn
                                               cp    cn
                                               np nc nn)))
                                    (buffer-substring p (+ p 1))))
                                 (t
                                  " "))))
                      (with-current-buffer tmpbuf
                        (insert str)))))
                (pop rest-prev-line)
                (pop rest-curr-line)
                (pop rest-next-line)))
            ;; End of line.
            (with-current-buffer tmpbuf
              (skip-chars-backward " ")
              (delete-region (point) (line-end-position))
              (insert "\n"))
            (prog1
                ;; Condition of terminate outer loop.
                ;;
                ;; The generated output is one line longer than TO,
                ;; since new cells can be born below the last line.
                (< (point) to)
              ;; Prepare for the next line.
              (forward-line)
              (setq prev-line curr-line)
              (setq curr-line next-line)
              (setq next-line (gameoflife-nonspace-points-on-next-line)))))))
  ;; Trim empty lines from end of buffer.
  (with-current-buffer tmpbuf
    (while (and (not (bobp))
                (progn
                  (backward-char)
                  (bolp)))
      (delete-char 1))
    (goto-char (point-min)))
  tmpbuf)


(defvar gameoflife-cached-buffers '())


(defun gameoflife-window (&optional win)
  "Display the next Game of Life anmation in WIN.

When WIN is nil, use the selected window."
  (interactive)
  (unless win
    (setq win (selected-window)))
  ;; Find a suitable gameoflife buffer. This will replace the buffer
  ;; displayed in WIN.
  (let ((buf nil))
    (let ((rest gameoflife-cached-buffers))
      (while rest
        (if (or (not (buffer-live-p (car rest)))
                (get-buffer-window (car rest) t))
            (setq rest (cdr rest))
          (setq buf (car rest))
          (setq rest nil))))
    ;; Last resort. Allocate a new.
    (unless buf
      (setq buf (generate-new-buffer "*GameOfLife*"))
      (push buf gameoflife-cached-buffers))
    ;; --------------------
    (with-current-buffer (window-buffer win)
      ;; Note: Not using `window-end' since the resulting buffer
      ;; doesn't contain wrapped lines, whereas the source buffer may.
      (let ((end (save-excursion
                   (goto-char (window-start win))
                   (forward-line (window-height win))
                   (point))))
        (set-window-buffer win
                           (gameoflife-buffer (window-start win) end buf))
        (set-window-start win (with-current-buffer buf
                                (point-min)))))))


(defun gameoflife-all-windows ()
  "Step forward one generation in Game of Life in all windows."
  (let* ((orig-win (selected-window))
         (first-win (next-window nil 'not-minibuf t))
         (win first-win))
    (while (progn
             (save-excursion
               (unless (window-dedicated-p win)
                 (select-window win)
                 (gameoflife-window win)))
             (setq win (next-window win 'not-minibuf t))
             (not (eq win first-win))))
    (select-window orig-win)))


;;;###autoload
(defun gameoflife-animate (&optional count)
  "Animate Conway's Game of Life in all windows in all frames.

COUNT determines the number of generations to run.  When omitted,
the animation runs for ever.

When a user input is available, this function returns.

The content of the windows of the frame are used as the seed of
the animation."
  (interactive)
  ;; Note: This is like `save-window-configuration' for all frames.
  (let ((orig-frame (selected-frame))
        (window-configurations '()))
    (let ((frame orig-frame))
      (while (progn
               (push (cons frame (current-window-configuration frame))
                     window-configurations)
               (setq frame (next-frame frame))
               (not (eq frame orig-frame))))
      (unwind-protect
          (let ((win (selected-window))
                (generation 0))
            (while (and (not (input-pending-p))
                        (or (null count)
                            (< generation count)))
              (with-current-buffer (window-buffer win)
                (gameoflife-all-windows)
                (message "Generation %d" generation)
                (setq generation (+ generation 1))
                (sit-for gameoflife-animation-speed)))
            ;; When a count was given, stop and show the last
            ;; generation.
            (when count
              (sit-for most-positive-fixnum)))
        (dolist (pair window-configurations)
          (select-frame (car pair))
          (set-window-configuration (cdr pair)))
        (select-frame orig-frame)))))


;; -------------------------------------------------------------------
;; Screensaver
;;

(defvar gameoflife-screensaver-timer nil)

(defvar gameoflife-screensaver-generations 1000)

(defvar gameoflife-screensaver-timeout 60
  "The time, in seconds, before Gameoflife Screensaver Mode starts.")

(defun gameoflife-animate-with-limit ()
  "Run `gameoflife-animate' a limited number of generations.

The variable `gameoflife-screensaver-generations' controls the
number of generations to run."
  (interactive)
  (gameoflife-animate gameoflife-screensaver-generations))

;;;###autoload
(define-minor-mode gameoflife-screensaver-mode
  "Run Conway's Game of Life when Emacs has been idle for a while."
  nil
  nil
  nil
  :global t
  (when (timerp gameoflife-screensaver-timer)
    (cancel-timer gameoflife-screensaver-timer))
  (setq gameoflife-screensaver-timer nil)
  (when gameoflife-screensaver-mode
    (setq gameoflife-screensaver-timer
          (run-with-idle-timer gameoflife-screensaver-timeout t
                               #'gameoflife-animate-with-limit))))

(provide 'gameoflife)

;;; gameoflife.el ends here
