;; mod-version:3

;; This is a stateful fennel file helper.
;; Since I am a game developer, this is written out like a 2D game.

;;TODO: Needs to have a list of scopes within the scope! But not scopes that aren't within the scope that the cursor is in!
;;tt Failure to find scope, like a one line repl test:
;;tt Try to eval line, if blank:
;;tt Eval last scope entry point

;; Core components
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

;; Plugins
(local uber (require :plugins.fennel_helpers.uber_match_paren))
;; (local bracketmatch (require :plugins.bracketmatch))


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

;; (fn set-pos-from-doc [pos y x]
;;   "Doc selection is Y (line) X (column) inverted, so we must fix it."
;;   (tset pos :x x)
;;   (tset pos :y y))

(fn decompile-pos [pos]
  "Decompile a position so it can be passed directly into function as X Y."
  (values (get-x pos) (get-y pos)))

(fn less-than [pos1 pos2]
  "Check if position 1 is less than position 2."
  (or (< (get-x pos1) (get-x pos2))
      (< (get-y pos1) (get-y pos2))))

(fn greater-than [pos1 pos2]
  "Check if position 1 is greater than position 2."
  (or (> (get-x pos1) (get-x pos2))
      (> (get-y pos1) (get-y pos2))))

(fn hit-lock []
  "Find if the current position has finally hit the lock position.
This is so the scanner doesn't get stuck in an infinite loop!"
  (not (less-than current-position lock-position)))

(fn debug-pos [pos info-text]
  "Print the current position of the helper cursor."
  (let [info-text (or info-text "position")]
    (print (string.format "%s: ( %s | %s )" info-text (get-x pos) (get-y pos)))))

(fn active-doc []
  "Shorthand for getting the current active document or nil."
  core.active_view.doc)

(fn init-position [doc]
  "Sets the scope searcher's initial position."
  (set-pos lock-position (doc:get_selection))
  (debug-pos lock-position "Lock"))

(fn update-position [doc]
  "Update's the scope searcher's current position."
  (set-pos current-position (doc:get_selection)))

(fn move-forward [doc]
  "Move the cursor to the next position."
  (doc:move_to translate.next_char)
  (update-position doc))

(fn scan-init [doc]
  "Move the cursor back to the beginning. Let's find that scope."
  (init-position doc)
  (doc:move_to translate.start_of_doc)
  (set-pos current-position (doc:get_selection))
  (debug-pos current-position "Current"))


(fn scan [doc]
  (var solved false)
  (print "scanning")
  (while (not solved)

    (debug-pos current-position "Current")

    (move-forward doc)
    (if (hit-lock)
        (set solved true))))


(fn begin-scope-scan []
  (print "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
  (when (active-doc)
    ;; Here we LOCK the position in. We're gonna see if we can overshoot it.
    (let [doc (active-doc)]
      (scan-init doc)
      (scan doc))))


(local new-commands {})
(tset new-commands "fennel_helpers:test" begin-scope-scan)
(command.add nil new-commands)

(local new-keymaps {})
(tset new-keymaps "f10" "fennel_helpers:test")
(keymap.add new-keymaps)


