;; mod-version:3

;; This is a stateful fennel file helper.
;; Since I am a game developer, this is written out like a 2D game.

;;TODO: Needs to have a list of scopes within the scope! But not scopes that aren't within the scope that the cursor is in!
;;tt Failure to find scope, like a one line repl test:
;;tt Try to eval line, if blank:
;;tt Eval last scope entry point

(fn test []
  (print "test"))

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
(local fennel (require :plugins.fennel_compiler))


;; BASE EMACS STYLE WALKER

;; The initial position given to the algorithm.
(var lock-position {:x 0
                    :y 0})

;; Current position of the helper cursor.
(var current-position {:x 0
                       :y 0})

;; WARNING: Min and Max are defined just for visualization!
;; WARNING: These become nil during runtime to prevent uncatchable errors!
;; Min helper position. Used for scope identification.
(var scope-start-position {:x 0
                           :y 0})

;; Max helper position. Used for scope identification.
(var scope-end-position {:x 0
                         :y 0})

(fn make-position [x y]
  "Make a position table from a raw X and Y numeric input."
  {:x x
   :y y})

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

(fn less-than-equal-to [pos1 pos2]
  "Check if position 1 is less than or equal to position 2."
  (or (<= (get-x pos1) (get-x pos2))
      (<= (get-y pos1) (get-y pos2))))

(fn greater-than [pos1 pos2]
  "Check if position 1 is greater than position 2."
  (and (> (get-x pos1) (get-x pos2))
       (> (get-y pos1) (get-y pos2))))

(fn greater-than-equal-to [pos1 pos2]
  "Check if position 1 is greater than or equal to position 2."
  (and (>= (get-x pos1) (get-x pos2))
       (>= (get-y pos1) (get-y pos2))))

(fn debug-pos [pos info-text]
  "Print the current position of the helper cursor."
  (let [info-text (or info-text "position")]
    (print (string.format "%s: ( %s | %s )" info-text (get-x pos) (get-y pos)))))

(fn hit-lock []
  "Find if the current position has finally hit the lock position.
This is so the scanner doesn't get stuck in an infinite loop!"
  (not (less-than current-position lock-position)))

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

(fn scope-check [local-position]
  "Test if the current bracket match is within the scope of the current position lock."
  (print "-=-scope check-=-")
  (debug-pos local-position "local")
  (debug-pos lock-position "lock ")
  (greater-than-equal-to local-position lock-position))

(fn extract-text [doc]
  "Extract the text out of the found scope selection."
  (doc:get_text
   (get-x scope-start-position)
   (get-y scope-start-position)
   (get-x scope-end-position)
   (+ (get-y scope-end-position) 1)))

(fn scan [doc]
  "Scan the document for the lisp scope of the current cursor position to shovel into REPL."
  ;; Will return solved
  (var solved false)
  (print "scanning")
  (while (not solved)

    ;; (debug-pos current-position "Current")
    (move-forward doc)

    ;; This is a decompilation & recompilation because got-x can also be nil.
    (let [(current-x current-y) (decompile-pos current-position)
          (got-x got-y) (uber.match doc current-x current-y)]
      (when got-x
        (let [local-position (make-position got-x got-y)
              in-scope (scope-check local-position)]
          (print "Found outer scope?" in-scope)
          (print got-x got-y)
          (when in-scope
            (print "we found our scope")
            (set solved true)
            ;; And now we mark the min and max for the next function to use.
            (set scope-start-position (make-position current-x current-y))
            (set scope-end-position (make-position got-x got-y))))))

    (if (hit-lock)
        (lua :break)))
  ;; Return back if we managed to solve the scope resolution.
  ;; The min and max of the scope are external, so they can be used without problem.
  solved)


(fn begin-scope-scan []
  (print "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
  (when (active-doc)
    ;; First we nullify the scope position to prevent errors!
    (set scope-start-position nil)
    (set scope-end-position nil)
    ;; Here we LOCK the position in. We're gonna see if we can overshoot it.
    (let [doc (active-doc)]
      (scan-init doc)
      (let [success (scan doc)]
        (if success
            (do
              (debug-pos scope-start-position "scope-start")
              (debug-pos scope-end-position   "scope-end  ")
              (print (extract-text doc)))
            (do
              (print "gotta try to run the line here!")))))))


(local new-commands {})
(tset new-commands "fennel_helpers:test" begin-scope-scan)
(command.add nil new-commands)

(local new-keymaps {})
(tset new-keymaps "f10" "fennel_helpers:test")
(keymap.add new-keymaps)


