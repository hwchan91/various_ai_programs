(defun mappend (fn list)
    (if (null list)
        nil
        (append (funcall fn (first list))
        (mappend fn (rest list)))
    )
)

(defparameter *simple-grammar*
    '(
    (sentence -> (noun-phrase verb-phrase))
    (noun-phrase -> (Article Noun))
    (verb-phrase -> (Verb noun-phrase))
    (Article -> the a)
    (Noun -> man ball woman table)
    (Verb -> hit took saw liked)
    )
)


(defparameter *bigger-grammar*
    '(
    (sentence -> (noun-phrase verb-phrase))
    (noun-phrase -> (Article Adj* Noun PP*) (Name) (Pronoun))
    (verb-phrase -> (Verb noun-phrase PP*))
    (PP* -> () (PP PP*))
    (Adj* -> () (Adj Adj*))
    (PP -> (Prep noun-phrase))
    (Prep -> to in by with on)
    (adj -> big little blue green adabatic)
    (Article -> the a)
    (Name -> Pat Kim Lee Terry Robin)
    (Noun -> man ball woman table)
    (Verb -> hit took saw liked)
    (Pronoun -> he she it these those that)
    )
)

(defvar *grammar* *simple-grammar*)

(defun rule-rhs (rule)
    (rest (rest rule))
)
(defun rewrites (category)
    (rule-rhs (assoc category *grammar*))
)

(defun random-elt (choices)
    (elt choices (random (length choices)))
)

(defun generate (phrase)
    (cond (
        (listp phrase) (mappend 'generate phrase))
        ((rewrites phrase) (generate (random-elt (rewrites phrase))))
        (t (list phrase))
    )
)

(print (generate `sentence))
(setq *grammar* *bigger-grammar*)
(print (generate `sentence))
