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


uber
