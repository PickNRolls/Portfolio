Interactive Widgets
===================
Every widget has own class.
- Clock
- ScrollSlider
- SelectList
- Counter

Each widget has methods:
- getClassList (expression): with true value returns classlist like string, else like array
- getElement: returns HTML Element, with which it'll work
- start: initializing object and append it to DOM

and accepts object like config with these properties:
- element (HTML Element, now can accept only one element, not HTMLCollection)
- classes (type - string, but if you need several classnames you must input array with strings, like this ['my-class', 'class'])

- Clock class accepts in config "clickable"-field (true if clickable, false is default value)