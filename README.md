# Frege-1879
Electronic book of Gottlob Frege's 1879 book *Begriffsschrift*.

## Goal

The goal is to make an easily distributable electronic book of Gottlob
Frege, *Begriffsschrift: eine der arithmetischen nachgebildete
Formelsprache des reinen Denkens* (Halle: Nebert, 1879).

My plan is to publish the electronic book on at least one or two of
the most prominent ebook stores (Kindle, Google Play, ...), and also
to make it freely available through Github.  

## Current status

The text has been transcribed and the formulas have been checked for
grammatical correctness.  SVG equivalents for all formulas and
inference chains in Parts I and II have been generated.

For the moment, this repository is private; I plan to make it public
before Balisage 2023.

## To do

To do (not necessarily in this order):
  
* SVG generation

  - Find SVG representations for the new notations introduced in Part
    III.

  - Write XSLT to generate SVG for formulas using those new notations.

  - Generate SVG versions of formulas for part III.

* Spelling 

  - Spell check using the framework at my spell-checking-XML
    repository, either by part or (probably nicer) by section.

* Markup

  - The handling of the signature labels needs work.

  - Some formulas require either footnotes or text-critical apparatus.

* SVG handling

  - The sizing of the SVG needs to align with the sizing of the base
    text.  So the SVG needs to be re-generated using rem units, not
    ems.

  - In Firefox, SVG images loaded via img don't load SVG images
    referred to via img.  Find a workaround.  (This is a problem for
    the table of contraries and contradictories in section 12, p. 24.)

* Cosmetic

  - The library stamps and handwritten additions need better styling.

  - The title page needs better styling.

  - The table of contents needs to become live, and the generated toc
    needs to go away, or they need to be merged, or ... something.

  - Simple (unbulleted, unnumbered) lists need to be supported.

* Proofread all formulas.

* Generate test versions of an EPub version of the book, test
  behaviors in selected e-book readers (Google Play, iBooks, Kindle,
  Nook); experiment as needed with different ways of handling the SVG.
  (I would *really* like to avoid having to fall back to PNG images of
  the formulas.)


## License

As far as I can tell, Frege's text is in the public domain world wide.
The book was published in 1879. According to Wikipedia, Frege died in
1925, so in any country with a copyright term of the life of the
author plus 50, 60, 70, 75, 80, or 95 years, the term of copyright has
elapsed.

As regards the other material here, I am not currently certain how
best to license it.  For the moment, the following terms apply (the
Markdown needs work, sorry):

  - The TEI markup, the kB grammar for keyboarding Begriffsschrift,
    the kB transcripts of the formulas, and the SVG representations of
    the formulas are all <a rel="license"
    href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img
    alt="Creative Commons License" style="border-width:0"
    src="https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png"
    /></a>licensed under a <a rel="license"
    href="http://creativecommons.org/licenses/by-nc-sa/4.0/">Creative
    Commons Attribution-NonCommercial-ShareAlike 4.0 International
    License</a>.
  
  - All XSLT and CSS code, whether for generating the SVG or for
    styling the book, is licensed under the GNU General Public License
    3.0 (link needed).

