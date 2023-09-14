;; mod-version:3

(local uber {})

(local bracket-maps
       [{40 41 91 93 123 125 :direction 1}
        {41 40 93 91 125 123 :direction (- 1)}])

(fn uber.get-token-at [doc line col]
  (var column 0)
  (each [_ type text (doc.highlighter:each_token line)]
    (set column (+ column (length text)))
    (when (>= column col) (lua "return type, text"))))	

(fn uber.get-matching-bracket [doc
                               line
                               col
                               line-limit
                               open-byte
                               close-byte
                               direction]
  "Raw bracket matcher for uber match."
  (let [end-line (+ line (* line-limit direction))]
    (var depth 0)
    (while (not= line end-line)
      (local byte (: (. doc.lines line) :byte col))
      (if (and (= byte open-byte) (not= (uber.get-token-at doc line col) :comment))
          (set depth (+ depth 1))
          (and (= byte close-byte) (not= (uber.get-token-at doc line col) :comment))
          (do
            (set depth (- depth 1))
            (when (= depth 0) (lua "return line, col"))))
      (local (prev-line prev-col) (values line col))
      (set-forcibly! (line col) (doc:position_offset line col direction))
      (when (and (= line prev-line) (= col prev-col)) (lua :break)))))

;;TODO: This can be used to collect scope!
;;tt Use this to do the red emacs parentheses things!
(fn uber.match [doc line col]
  (let [line-limit math.huge]
    (var (line2 col2) nil)
    (var found false)
    (each [_ map (ipairs bracket-maps)]
      (when found (lua :break))
      
      (when found (lua :break))
      (local (line col) (doc:position_offset line col 0))
      (local open (: (. doc.lines line) :byte col))
      (local close (. map open))
      (when (and close (not= (uber.get-token-at doc line col) :comment))
        (set (line2 col2)
             (uber.get-matching-bracket doc line col line-limit open close
                                        map.direction))
        (set found true)))
    (when (not found) (lua "return nil"))
    (values line2 col2)))

uber
