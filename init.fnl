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

;; The initial position given to the algorithm.
(var lock-position {:x 0
                    :y 0})

;; Current position of the helper cursor.
(var current-position {:x 0
                       :y 0})
;; Min helper position. Used for scope identification.
(var scope-start-position {:x 0
                   :y 0})
;; Max helper position. Used for scope identification.
(var scope-end-position {:x 0
                   :y 0})

;;TODO: Needs to have a list of scopes within the scope! But not scopes that aren't within the scope that the cursor is in!
;; Failure to find scope, like a one line repl test:
;; Try to eval line, if blank:
;; Eval last scope entry point

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

(fn less-than [pos1 pos2]
  ;; Check if position 1 is less than position 2.
  (and (< (get-x pos1) (get-x pos2))
       (< (get-y pos1) (get-y pos2))))

(fn debug-pos [pos info-text]
  "Print the current position of the helper cursor."
  (let [info-text (or info-text "position")]
    (print (string.format "%s: ( %s | %s )" info-text (get-x pos) (get-y pos)))))

(fn active-doc []
  "Shorthand for getting the current active document or nil."
  core.active_view.doc)

(fn init-position []
  "Sets the scope searcher's initial position."
  (when (active-doc)
    (let [doc (active-doc)]
      (set-pos-from-doc-selection current-position (doc:get_selection))
      (set-pos-from-doc-selection lock-position (doc:get_selection))
      (debug-pos current-position "Current")
      (debug-pos current-position "Lock"))))

(fn update-position []
  "Update's the scope searcher's current position."
  (when (active-doc)
    (let [doc (active-doc)]
      (set-pos-from-doc-selection current-position (doc:get_selection)))))

(fn at-beginning-of-line []
  "Check if the helper cursor has reached the beginning of a line."
  (<= (get-x current-position) 1))


(fn walk-back []
  (print "back we go"))

(fn scan-init [doc]
  (doc:move_to translate.start_of_doc))

(fn begin-scope-scan []
  ;; Here we LOCK the position in. We're gonna see if we can overshoot it.
  (init-position)
  (when (active-doc)
    (let [doc (active-doc)]
      (scan-init doc))))


(local new-commands {})
(tset new-commands "fennel_helpers:test" begin-scope-scan)
(command.add nil new-commands)

(local new-keymaps {})
(tset new-keymaps "f10" "fennel_helpers:test")
(keymap.add new-keymaps)
