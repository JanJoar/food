;;; food.el --- Render "What Joar is Having" with org-static-blog -*- lexical-binding: t; -*-

;; Author: Joar von Arndt
;; Homepage: https://joarvarndt.se/food/

;;; Commentary:

;; Configuration and homepage renderer for the food sub-blog.  Every
;; post lives in `food-posts-directory' and is named after the day it
;; covers (YYYY-MM-DD.org).  The matching photograph lives in
;; `food-images-directory' under the same basename.
;;
;; The homepage is a calendar: one section per month, seven columns
;; starting on Monday, one cell per day.  A day with a post shows its
;; thumbnail and links to the post page; a day without one shows an
;; empty outline.  Nothing here reads a hand-maintained index; the grid
;; is derived entirely from the post filenames.
;;
;; Load order (see ../build):
;;
;;   (load-file "~/programming/org-static-blog/utils.el")
;;   (load-file "~/programming/org-static-blog/org-static-blog.el")
;;   (load-file "~/Documents/blog/food/food.el")
;;   (food-publish)

;;; Code:

(require 'calendar)
(require 'subr-x)

;;; Paths and settings

(defvar food-images-directory (concat org-static-blog-publish-directory "images/")
  "Directory of full-size photographs, each named YYYY-MM-DD.<ext>.")

(defvar food-thumbnail-directory (concat org-static-blog-publish-directory "static/thumbs/")
  "Directory for generated calendar thumbnails.")

(defvar food-preview-directory (concat org-static-blog-publish-directory "static/previews/")
  "Directory for generated hover-preview images.")

(defvar food-display-directory (concat org-static-blog-publish-directory "static/display/")
  "Directory for generated full-width images used on day pages.")

(defvar food-image-extensions '("webp" "jpg" "jpeg" "png")
  "Extensions searched, in order, when looking for a day's photograph.")

(defvar food-thumbnail-width 600
  "Pixel width of calendar thumbnails.")

(defvar food-thumbnail-height 800
  "Pixel height of calendar thumbnails.  Keep the CSS aspect-ratio in step.")

(defvar food-preview-width 900
  "Pixel width of the uncropped hover-preview image.")

(defvar food-display-width 1600
  "Pixel width of the image shown on a day page.")

(defvar food-identify-program "identify"
  "ImageMagick identify executable.")

(defvar food-calendar-first-weekday 1
  "First column of the grid: 0 for Sunday, 1 for Monday.")

(defun food-configure ()
  "Point org-static-blog at the food sub-blog."
  (setq org-static-blog-publish-title "What Joar is Having"
        org-static-blog-publish-url "https://joarvarndt.se/food/"
        org-static-blog-publish-directory (expand-file-name "~/Documents/blog/food/")
        org-static-blog-posts-directory (expand-file-name "~/Documents/blog/food/posts/")
        org-static-blog-drafts-directory (expand-file-name "~/Documents/blog/food/drafts/")
        org-static-blog-hidden-directory (expand-file-name "~/Documents/blog/food/hidden/")
        org-static-blog-index-file "index.html"
        org-static-blog-archive-file "archive.html"
        org-static-blog-rss-file "rss.xml"
        org-static-blog-enable-tags nil
        org-static-blog-enable-tag-rss nil
        org-static-blog-enable-og-tags t
        org-static-blog-generate-og-images nil
        org-static-blog-use-preview nil
        org-static-blog-display-git-date nil
        org-static-blog-title-link nil
        org-static-blog-langcode "en"
        org-image-actual-width nil
        org-export-with-toc nil
        org-export-with-section-numbers nil
        org-export-with-broken-links t)
  (setq food-images-directory (concat org-static-blog-publish-directory "images/")
        food-thumbnail-directory (concat org-static-blog-publish-directory "static/thumbs/")
        food-preview-directory (concat org-static-blog-publish-directory "static/previews/")
        food-display-directory (concat org-static-blog-publish-directory "static/display/"))
  (setq org-static-blog-page-header
        (concat
         "<meta name=\"viewport\" content=\"initial-scale=1,width=device-width,minimum-scale=1\">\n"
         "<meta name=\"referrer\" content=\"no-referrer\">\n"
         "<script src=\"../static/comments.js\" defer></script>"
         "<link href=\"./static/food.css\" rel=\"stylesheet\" type=\"text/css\" />\n"
         "<link rel=\"icon\" href=\"../static/favicon.ico\">\n"))
  (setq org-static-blog-page-preamble
        (concat
         "<div class=\"header\" id=\"food-header\" role=\"banner\">\n"
         "<a href=\"https://joarvarndt.se/\" class=\"home-link\"><img id=\"themeImageHeader\" src=\"../vonArndtCrestBlack.png\" class=\"header-img\" alt=\"Crest\" width=\"50\"></a>\n"
         "</div>\n"))
  (setq org-static-blog-page-postamble
        (concat
         "<div id=\"postamble\" class=\"status\"><div class=\"footer\" role=\"contentinfo\">
         <div class=\"footer-upper\">
         <footer-img><img loading=\"lazy\" class=\"footer-img\" id=\"themeImageFooter\" src=\"../Ship-5.svg\" alt=\"Set sail on the sea of knowledge\"></footer-img>
         <copyright>© 2026 <span class=\"small-caps\">ad</span> / <a href=\"https://en.wikipedia.org/wiki/French_Republican_calendar\">234 <span class=\"small-caps\">ar</span></a> Joar von Arndt</copyright>
         </div>
         <div class=\"footer-lower\">
         <nav>
         <ul>
         <li><a href=\"https://joarvarndt.se/about.html\">About</a></li>
         <li><a href=\"https://joarvarndt.se/archive.html\">Archive</a></li>
         <li><a href=\"https://joarvarndt.se/links.html\">Your next stop</a></li>
         <li><a href=\"https://joarvarndt.se/website.html\">Colophon</a></li>
         </ul>
         </nav>

         <nav>
         <ul>
         <li><a href=\"https://joarvarndt.se/now.html\">Now</a></li>
         <li><a href=\"https://joarvarndt.se/subscribe.html\">Subscribe</a></li>
         <li><a href=\"https://joarvarndt.se/contact.html\">Contact</a></li>
         <li><a href=\"https://webmention.io/joarvarndt.se/webmention\">Webmentions</a></li>
         </ul>
         </nav>
         <script src=\"../static/theme.js\"></script>
         </div></div></div>"))
  (setq org-static-blog-post-comments
        "<div class=\"comment-by-email\">
         <form class=\"comment-by-email-form\">
           <textarea id=\"comment-by-email-textarea\"
             placeholder=\"Write a comment\"></textarea>
           <button type=\"submit\">Send</button>
         </form>
       </div>")
  (setq org-static-blog-index-front-matter
        (concat
         "<p>Everything I have eaten worth photographing,"
         " as well as the little things not worth recording."
         " One picture a day. </p>\n"
         "<p>During my travels to the Chinese mainland, I was asked to photograph"
         " and document everything that I ate."
         " Since returning I have found this resource increadibly useful,"
         " not only as a source of memories but also as a form of inspiration for cooking at home."
         " It is my hope that this serves as an inspiration to you, as well as a form of remeberence"
         " of my time in the Republic of China (中華民國)."
         "</p>\n")))

;;; Dates from filenames

(defun food-post-date (post-filename)
  "Return (YEAR MONTH DAY) parsed from the basename of POST-FILENAME.  Return nil when the basename is not a YYYY-MM-DD date."
  (let ((base (file-name-base post-filename)))
    (when (string-match "\\`\\([0-9]\\{4\\}\\)-\\([0-9]\\{2\\}\\)-\\([0-9]\\{2\\}\\)\\'" base)
      (list (string-to-number (match-string 1 base))
            (string-to-number (match-string 2 base))
            (string-to-number (match-string 3 base))))))

(defun food-day-slug (year month day)
  "Return the YYYY-MM-DD slug for YEAR MONTH DAY."
  (format "%04d-%02d-%02d" year month day))

(defun food-day-long-name (year month day)
  "Return a human date such as \"26 July 2026\" for YEAR MONTH DAY."
  (format-time-string "%-d %B %Y" (encode-time 0 0 12 day month year)))

(defun food-month-long-name (year month)
  "Return a human month such as \"July 2026\" for YEAR MONTH."
  (format-time-string "%B %Y" (encode-time 0 0 12 1 month year)))

(defun food-column-of-day (year month day)
  "Return the zero-based grid column for YEAR MONTH DAY."
  (mod (- (calendar-day-of-week (list month day year))
          food-calendar-first-weekday)
       7))

(defun food-weekday-labels ()
  "Return abbreviated weekday names ordered by `food-calendar-first-weekday'."
  (let (labels)
    (dotimes (i 7)
      (push (aref calendar-day-name-array
                  (mod (+ food-calendar-first-weekday i) 7))
            labels))
    (mapcar (lambda (name) (substring name 0 3)) (nreverse labels))))

(defun food-posts-by-day ()
  "Return an alist of (SLUG . POST-FILENAME) for every dated post, sorted."
  (let (posts)
    (dolist (file (directory-files org-static-blog-posts-directory t "\\.org\\'"))
      (when (food-post-date file)
        (push (cons (file-name-base file) file) posts)))
    (sort posts (lambda (a b) (string< (car a) (car b))))))

(defun food-months-covered (posts)
  "Return (YEAR . MONTH) pairs covered by POSTS, newest first."
  (let (months)
    (dolist (entry posts)
      (let* ((date (food-post-date (cdr entry)))
             (pair (cons (nth 0 date) (nth 1 date))))
        (unless (member pair months)
          (push pair months))))
    (sort months (lambda (a b)
                   (or (> (car a) (car b))
                       (and (= (car a) (car b)) (> (cdr a) (cdr b))))))))

;;; Photographs and derivatives

(defun food-source-image (slug)
  "Return the full-size photograph for SLUG, or nil if there is none."
  (seq-find #'file-exists-p
            (mapcar (lambda (ext) (concat food-images-directory slug "." ext))
                    food-image-extensions)))

(defun food--stale-p (target source)
  "Return non-nil when TARGET is missing or older than SOURCE."
  (not (and (file-exists-p target)
            (file-newer-than-file-p target source))))

(defun food--run-magick (&rest args)
  "Run ImageMagick with ARGS, logging failures."
  (let ((status (apply #'call-process "convert" nil
                       (get-buffer-create "*food-magick*") nil args)))
    (unless (eq status 0)
      (message "food: convert failed (%s) for %S" status args))
    (eq status 0)))

(defun food-thumbnail (slug)
  "Return the relative URL of the calendar thumbnail for SLUG, generating it.
         Return nil when SLUG has no photograph."
  (let ((source (food-source-image slug)))
    (when source
      (make-directory food-thumbnail-directory t)
      (let* ((geometry (format "%dx%d" food-thumbnail-width food-thumbnail-height))
             (target (concat food-thumbnail-directory
                             (format "%s-%s-crop.webp" slug geometry))))
        (when (food--stale-p target source)
          (food--run-magick source
                            "-auto-orient"
                            "-resize" (concat geometry "^")
                            "-gravity" "center"
                            "-extent" geometry
                            "-quality" "80"
                            "-strip"
                            target))
        (when (file-exists-p target)
          (concat "./static/thumbs/" (file-name-nondirectory target)))))))

(defun food-preview (slug)
  "Return the relative URL of the uncropped hover preview for SLUG.
         Return nil when SLUG has no photograph."
  (let ((source (food-source-image slug)))
    (when source
      (make-directory food-preview-directory t)
      (let ((target (concat food-preview-directory
                            (format "%s-%dx.webp" slug food-preview-width))))
        (when (food--stale-p target source)
          (food--run-magick source
                            "-auto-orient"
                            "-resize" (format "%d>" food-preview-width)
                            "-quality" "82"
                            "-strip"
                            target))
        (when (file-exists-p target)
          (concat "./static/previews/" (file-name-nondirectory target)))))))

(defun food-display-image (slug)
  "Return the relative URL of the day-page image for SLUG, generating it.
         Return nil when SLUG has no photograph."
  (let ((source (food-source-image slug)))
    (when source
      (make-directory food-display-directory t)
      (let ((target (concat food-display-directory
                            (format "%s-%dx.webp" slug food-display-width))))
        (when (food--stale-p target source)
          (food--run-magick source
                            "-auto-orient"
                            "-resize" (format "%d>" food-display-width)
                            "-quality" "84"
                            "-strip"
                            target))
        (when (file-exists-p target)
          (concat "./static/display/" (file-name-nondirectory target)))))))

(defun food-image-dimensions (slug)
  "Return (WIDTH . HEIGHT) of the photograph for SLUG, or nil."
  (let ((source (food-source-image slug)))
    (when source
      (with-temp-buffer
        (when (eq 0 (call-process food-identify-program nil t nil
                                  "-format" "%w %h" (concat source "[0]")))
          (let ((parts (split-string (string-trim (buffer-string)))))
            (when (= (length parts) 2)
              (cons (string-to-number (nth 0 parts))
                    (string-to-number (nth 1 parts))))))))))

;;; Captions

(defun food-post-caption (post-filename)
  "Return the caption of POST-FILENAME as plain text, or nil.
         Prefers `#+description:', otherwise the first line of body text that is
         neither a keyword nor a bare link."
  (or (org-static-blog-get-description post-filename)
      (with-temp-buffer
        (insert-file-contents post-filename)
        (goto-char (point-min))
        (let (caption)
          (while (and (not caption) (not (eobp)))
            (let ((line (string-trim (buffer-substring-no-properties
                                      (line-beginning-position)
                                      (line-end-position)))))
              (unless (or (string-empty-p line)
                          (string-prefix-p "#+" line)
                          (string-prefix-p "#" line)
                          (string-match-p "\\`\\[\\[.*\\]\\]\\'" line))
                (setq caption line)))
            (forward-line 1))
          caption))))

(defun food-cell-alt-text (slug caption)
  "Return alt text for SLUG's thumbnail, using CAPTION when available."
  (let ((date (food-post-date (concat slug ".org"))))
    (if (and caption (not (string-empty-p caption)))
        caption
      (format "Food eaten on %s"
              (apply #'food-day-long-name date)))))

;;; The calendar

(defun food-render-cell (year month day posts)
  "Return the HTML for one calendar cell.
         POSTS is the alist from `food-posts-by-day'."
  (let* ((slug (food-day-slug year month day))
         (post (cdr (assoc slug posts)))
         (label (food-day-long-name year month day)))
    (if (not post)
        (concat "<article class=\"food-cell is-empty\" aria-label=\"" label "\">\n"
                "<div class=\"food-cell-placeholder\" aria-hidden=\"true\"></div>\n"
                "<div class=\"food-cell-footer\"><span class=\"food-day-number\">"
                (number-to-string day) "</span></div>\n"
                "</article>\n")
      (let* ((thumb (food-thumbnail slug))
             (preview (food-preview slug))
             (dimensions (food-image-dimensions slug))
             (caption (food-post-caption post))
             (alt (food-cell-alt-text slug caption))
             (href (concat "./" (org-static-blog-get-relative-path post))))
        (concat
         "<article class=\"food-cell has-entry\" aria-label=\"" label "\">\n"
         "<a href=\"" href "\" class=\"food-entry-link\""
         (when preview
           (concat "\n   data-preview-src=\"" preview "\""
                   "\n   data-preview-alt=\"" (food--escape alt) "\""
                   (when dimensions
                     (concat "\n   data-preview-width=\""
                             (number-to-string (car dimensions)) "\""
                             "\n   data-preview-height=\""
                             (number-to-string (cdr dimensions)) "\""))))
         ">\n"
         (if thumb
             (concat "<img src=\"" thumb "\" alt=\"" (food--escape alt) "\""
                     " width=\"" (number-to-string food-thumbnail-width) "\""
                     " height=\"" (number-to-string food-thumbnail-height) "\""
                     " loading=\"lazy\" decoding=\"async\" />\n")
           (concat "<span class=\"food-cell-missing\">" (food--escape alt) "</span>\n"))
         "</a>\n"
         "<div class=\"food-cell-footer\">"
         "<time class=\"food-day-number\" datetime=\"" slug "\">"
         (number-to-string day) "</time>"
         "</div>\n"
         "</article>\n")))))

(defun food--escape (text)
  "Escape TEXT for use inside an HTML attribute."
  (if (null text)
      ""
    (thread-last text
                 (replace-regexp-in-string "&" "&amp;")
         (replace-regexp-in-string "<" "&lt;")
         (replace-regexp-in-string ">" "&gt;")
         (replace-regexp-in-string "\"" "&quot;"))))

(defun food-render-month (year month posts)
  "Return the HTML for the YEAR MONTH grid, filled from POSTS."
  (let ((last-day (calendar-last-day-of-month month year))
        (offset (food-column-of-day year month 1)))
    (concat
     "<section class=\"food-month\" aria-labelledby=\"month-"
     (format "%04d-%02d" year month) "\">\n"
     "<h2 class=\"food-month-header\" id=\"month-"
     (format "%04d-%02d" year month) "\">"
     (food-month-long-name year month) "</h2>\n"
     "<div class=\"food-weekdays\" aria-hidden=\"true\">"
     (mapconcat (lambda (label) (concat "<span>" label "</span>"))
                (food-weekday-labels) "")
     "</div>\n"
     "<div class=\"food-grid\">\n"
     (mapconcat (lambda (_)
                  "<div class=\"food-cell food-cell-pad\" aria-hidden=\"true\"></div>\n")
                (number-sequence 1 offset) "")
     (mapconcat (lambda (day) (food-render-cell year month day posts))
                (number-sequence 1 last-day) "")
     "</div>\n"
     "</section>\n")))

(defun food-calendar-html ()
  "Return the full calendar markup, newest month first."
  (let* ((posts (food-posts-by-day))
         (months (food-months-covered posts)))
    (concat
     "<div class=\"food-calendar\">\n"
     (if (null months)
         "<p class=\"food-empty\">No meals recorded yet.</p>\n"
       (mapconcat (lambda (pair) (food-render-month (car pair) (cdr pair) posts))
                  months ""))
     "</div>\n"
     "<div class=\"food-preview\" aria-hidden=\"true\"><img alt=\"\" /></div>\n"
     "<script src=\"./static/food.js\" defer></script>\n")))

(defun food-assemble-index ()
  "Write the calendar homepage to `org-static-blog-index-file'."
  (org-static-blog-with-find-file
   (concat-to-dir org-static-blog-publish-directory org-static-blog-index-file)
   (org-static-blog-template
    org-static-blog-publish-title
    (concat org-static-blog-index-front-matter (food-calendar-html))
    "Pictures of the food I'm having."
    nil
    org-static-blog-publish-url)))

;;; Post pages

(defun food-post-title (post-filename &optional _public)
  "Return the long date of POST-FILENAME as its title."
  (let ((date (food-post-date post-filename)))
    (if date
        (apply #'food-day-long-name date)
      (file-name-base post-filename))))

(defun food--title-override (orig post-filename &optional public)
  "Use the day as the title for dated posts, else defer to ORIG."
  (if (food-post-date post-filename)
      (food-post-title post-filename public)
    (funcall orig post-filename public)))

(defun food--date-override (orig post-filename)
  "Take the date from the filename when possible, else defer to ORIG."
  (let ((date (food-post-date post-filename)))
    (if date
        (encode-time 0 0 12 (nth 2 date) (nth 1 date) (nth 0 date))
      (funcall orig post-filename))))

(defun food-neighbour-links (post-filename posts)
  "Return prev/next navigation HTML for POST-FILENAME within POSTS."
  (let* ((slugs (mapcar #'car posts))
         (index (seq-position slugs (file-name-base post-filename)))
         (older (and index (> index 0) (nth (1- index) slugs)))
         (newer (and index (< index (1- (length slugs))) (nth (1+ index) slugs))))
    (concat
     "<nav id=\"table-of-contents\" aria-label=\"Entry navigation\">\n"
     "<h2 class=\"text-table-of-contents\">"
     (if older
         (concat "<a class=\"is-older\" href=\"./" older ".html\">"
                 "<span aria-hidden=\"true\">←</span>"
                 "<span class=\"sr-only\">Previous day</span></a>\n")
       "<span class=\"is-older is-disabled\" aria-hidden=\"true\"></span>\n")
     "<a class=\"food-entry-up\" href=\"./index.html\">Calendar</a>\n"
     (if newer
         (concat "<a class=\"is-newer\" href=\"./" newer ".html\">"
                 "<span aria-hidden=\"true\">→</span>"
                 "<span class=\"sr-only\">Next day</span></a>\n")
       "<span class=\"is-newer is-disabled\" aria-hidden=\"true\"></span>\n")
     "</h2>"
     "</nav>\n")))

(defun food-post-preamble (post-filename)
  "Return the header for POST-FILENAME: the date, then prev/next links."
  (concat
   "<div class=\"food-entry-header\">\n"
   "<h1 class=\"post-title\">" (food-post-title post-filename) "</h1>\n"
   (food-neighbour-links post-filename (food-posts-by-day))
   "</div>\n"))

;;; Rewriting the photograph in rendered day pages

(defun food--rewrite-images (html post-filename)
  "Point every photograph in HTML at its generated derivative.
Org links such as [[file:~/Documents/blog/food/images/2026-07-26.jpg]] export
as absolute file:// URLs, which only resolve on the machine that built the
site.  Rewrite them to the served derivative and give them real alt text."
  (let* ((slug (file-name-base post-filename))
         (display (food-display-image slug))
         (alt (food--escape (food-cell-alt-text slug (food-post-caption post-filename)))))
    (if (not display)
        html
      (replace-regexp-in-string
       "<img src=\"[^\"]*\" alt=\"[^\"]*\""
       (lambda (match)
         (if (string-match-p (regexp-quote (concat slug ".")) match)
             (concat "<img src=\"" display "\" alt=\"" alt "\""
                     " loading=\"eager\" decoding=\"async\"")
           match))
       html t t))))

(defun food--render-content-override (orig post-filename)
  "Render POST-FILENAME via ORIG, then rewrite its photograph."
  (food--rewrite-images (funcall orig post-filename) post-filename))

;;; Entry point

(defun food-publish (&optional force-render)
  "Render every day page, then the calendar homepage.
With FORCE-RENDER non-nil, re-render posts whose HTML is up to date."
  (interactive "P")
  (setq org-export-with-smart-quotes t)
  (food-configure)
  (dolist (dir (list org-static-blog-posts-directory
                     food-images-directory
                     org-static-blog-drafts-directory
                     org-static-blog-hidden-directory))
    (make-directory dir t))
  (advice-add 'org-static-blog-get-title :around #'food--title-override)
  (advice-add 'org-static-blog-get-date :around #'food--date-override)
  (advice-add 'org-static-blog-post-preamble :override #'food-post-preamble)
  (advice-add 'org-static-blog-render-post-content :around #'food--render-content-override)
  (advice-add 'org-static-blog-assemble-index :override #'food-assemble-index)
  (unwind-protect
      (org-static-blog-publish force-render)
    (advice-remove 'org-static-blog-get-title #'food--title-override)
    (advice-remove 'org-static-blog-get-date #'food--date-override)
    (advice-remove 'org-static-blog-post-preamble #'food-post-preamble)
    (advice-remove 'org-static-blog-render-post-content #'food--render-content-override)
    (advice-remove 'org-static-blog-assemble-index #'food-assemble-index)))

(provide 'food)

;;; food.el ends here
