;;; gameoflife-screenshot-setup.el --- Setup Emacs for gameoflife screenshot

;; Copyright (C) 2020  Anders Lindgren

;; Author: Anders Lindgren

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

;; Usage:
;;
;;   emacs -q -l gameoflife-screenshot-setup.el
;;
;;   Start "linecap" (or any other screen grabbing utility), and
;;   resize it to match the Emacs frame.
;;
;;   Start the screengrabbing and press RET in Emacs.

;;; Code:

(setq inhibit-startup-screen t)

(blink-cursor-mode -1)

(defvar gameoflife-screenshot-dir
  (or (and load-file-name
           (file-name-directory load-file-name))
      default-directory))

(set-frame-size (selected-frame) 80 30)

(load (concat gameoflife-screenshot-dir
              "../gameoflife.el"))
(find-file (concat gameoflife-screenshot-dir "../gameoflife.el"))
(re-search-forward "(defun gameoflife-animate" nil)
(forward-line -3)
(set-window-start (selected-window) (point))

(provide 'gameoflife-screenshot-setup)

(setq unread-command-events
      (listify-key-sequence (kbd "M-x gameoflife-animate")))

;;; gameoflife-screenshot-setup.el ends here
