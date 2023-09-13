;; mod-version:3

;; This is a stateful fennel file helper.
;; Since I am a game developer, this is written out like a 2D game.

(local core (require :core))
(local config (require :core.config))
(local command (require :core.command))
(local style (require :core.style))
(local common (require :core.common))
(local View (require :core.view))
(local keymap (require :core.keymap))
(local StatusView (require :core.statusview))
(local DocView (require :core.docview))
(local translate (require :core.doc.translate))


;; BASE EMACS STYLE WALKER

;; Current position of the helper cursor.
(var current-position {:x 0
                       :y 0})
;; Min helper position. Used for scope identification.
(var min-position {:x 0
                   :y 0})
;; Max helper position. Used for scope identification.
(var max-position {:x 0
                   :y 0})

(fn get-x [pos]
  "Get the X component of a position table."
  (. pos :x))
  
(fn get-y [pos]
  "Get the Y component of a position table."
  (. pos :y))

(fn set-pos [pos x y]
  "Set the X and Y of a position table."
  (tset pos :x x)
  (tset pos :y y))

(fn set-pos-from-doc-selection [pos y x]
  "Doc selection is Y (line) X (column) inverted, so we must fix it."
  (tset pos :x x)
  (tset pos :y y))

(fn debug-pos [pos]
  "Print the current position of the helper cursor."
  (print (string.format "position: ( %s | %s )" (get-x pos) (get-y pos))))

(fn active-doc []
  "Shorthand for getting the current active document or nil."
  core.active_view.doc)

(fn init-position []
  "Sets the scope searcher's initial position."
  (when (active-doc)
    (let [doc (active-doc)]
      (set-pos-from-doc-selection current-position (doc:get_selection))
      (debug-pos current-position))))

(fn at-beginning-of-line []
  "Check if the helper cursor has reached the beginning of a line."
  (<= (get-x current-position) 1))


(fn walk-back []
  (print "back we go"))

(fn scan-init []
  (doc:move_to translate.start_of_doc))

(fn walk-debug []
  ;; Here we LOCK the position in. We're gonna see if we can overshoot it.
  (init-position)
  (when (active-doc)
    (let [doc (active-doc)]
      (scan-init))))


(local new-commands {})
(tset new-commands "fennel_helpers:test" walk-debug)
(command.add nil new-commands)

(local new-keymaps {})
(tset new-keymaps "f10" "fennel_helpers:test")
(keymap.add new-keymaps)
