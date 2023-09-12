;; mod-version:3

;; This is a stateful fennel file helper.

(local core (require :core))
(local config (require :core.config))
(local command (require :core.command))
(local style (require :core.style))
(local common (require :core.common))
(local View (require :core.view))
(local keymap (require :core.keymap))
(local StatusView (require :core.statusview))
(local DocView (require :core.docview))


(var current-position {:x 0
                       :y 0})
(var min-position {:x 0
                   :y 0})
(var max-position {:x 0
                   :y 0})

(fn get-x [pos]
  (. pos :x))
  
(fn get-y [pos]
  (. pos :y))

(fn set-pos [pos x y]
  (tset pos :x x)
  (tset pos :y y))

(fn set-pos-from-doc-selection [pos y x]
  "Doc selection is Y (line) X (column) inverted, so we must fix it."
  (tset pos :x x)
  (tset pos :y y))

(fn debug-pos [pos]
  (print (string.format "position: ( %s | %s )" (get-x pos) (get-y pos))))

(fn init-position []
  "Sets the scope searcher's initial position."
  (when core.active_view.doc
    (let [doc core.active_view.doc]
      (set-pos-from-doc-selection current-position (doc:get_selection))
      (debug-pos current-position))))


(local new-commands {})
(tset new-commands "fennel_helpers:test" init-position)
(command.add nil new-commands)

(local new-keymaps {})
(tset new-keymaps "f10" "fennel_helpers:test")
(keymap.add new-keymaps)
