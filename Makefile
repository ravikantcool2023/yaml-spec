.SUFFIXES: .dbk .html .dia .eps .png .pdf

# To make this work, you need:
# - perl, sed.
# - dia, if you want to edit the graphs.
# - docbook DTDs. Modify the "catalog" file to point to them.
# - docbook XSLT stylesheets. Modify DOCBOOK_XSLT below to point to them.
# - xsltproc.
# - xep. Modify XEP below to point to it.
# - ps2pdf, if you want to create the PDF files.

# This depends on where you installed xep.
XEP = /bin/sh /usr/local/XEP/xep.sh \
    -DLICENSE=Render-X-license.txt \
    -DTMPDIR=/tmp -quiet

# Get xsltproc to use the local XML catalog file.
XSLTPROC = SGML_CATALOG_FILES=catalog xsltproc --catalogs

# Each system places this somewhere else.
# Gentoo: /usr/share/sgml/docbook/xsl-stylesheets-1.65.1
# MAX OS C: /sw/share/xml/xsl/docbook-xsl
# Ubuntu: /usr/share/xml/docbook/stylesheet/nwalsh
# BSD: /usr/share/csl/docbook/
# Cygwin: /usr/share/docbook-xsl
DOCBOOK_XSLT = /usr/share/xml/docbook/stylesheet/nwalsh

HTML = \
  spec.html changes.html index.html type.html map.html seq.html str.html \
  bool.html binary.html float.html int.html merge.html null.html \
  timestamp.html value.html yaml.html omap.html pairs.html set.html

PS = \
  spec.ps changes.ps index.ps type.ps map.ps seq.ps str.ps \
  bool.ps binary.ps float.ps int.ps merge.ps null.ps \
  timestamp.ps value.ps yaml.ps omap.ps pairs.ps set.ps

PDF = \
  spec.pdf changes.pdf index.pdf type.pdf map.pdf seq.pdf str.pdf \
  bool.pdf binary.pdf float.pdf int.pdf merge.pdf null.pdf \
  timestamp.pdf value.pdf yaml.pdf omap.pdf pairs.pdf set.pdf

EPS_IMAGES = \
  model2.eps overview2.eps \
  present2.eps represent2.eps serialize2.eps styles2.eps validity2.eps

PNG_IMAGES = \
  model2.png overview2.png \
  present2.png represent2.png serialize2.png styles2.png validity2.png

all: html pdf

site: all
	mkdir site
	mkdir site/spec
	mkdir site/type
	mkdir site/spec/cvs
	cp type.html site/type/index.html
	cp type.pdf site/type/index.pdf
	cp type.ps site/type/index.ps
	for T in map seq str bool binary float int merge null timestamp value \
            yaml omap pairs set; do cp $$T.html $$T.pdf $$T.ps site/type; done
	cp spec.html site/spec/cvs/current.html
	cp spec.pdf site/spec/cvs/current.pdf
	cp spec.ps site/spec/cvs/current.ps
	cp $(PNG_IMAGES) site/spec/cvs
	cp single_html.css site/spec/cvs
	cp single_html.css site/type
	for F in changes index; do cp $$F.html $$F.pdf $$F.ps site/spec; done

site.tgz: site
	cd site && tar cvzf ../site.tgz *

html: $(HTML)

pdf: $(PDF)

clean:
	rm -f $(HTML) $(PDF) $(PS)

$(PDF): single_fo.xsl ebnf_fo.xsl preprocess_fo.xsl

$(HTML): single_html.xsl preprocess_html.xsl

.dbk.html: single_html.xsl catalog docbook_xslt
	$(XSLTPROC) single_html.xsl $*.dbk > $*.html

.dbk.pdf: single_fo.xsl Render-X-license.txt catalog docbook_xslt
	$(XSLTPROC) --param generate.toc "''" single_fo.xsl $*.dbk | sed 's/\xa0/\&#160;/g;s/\xa9/\&#169;/' > tmp.xml
	$(XEP) tmp.xml -ps $*.ps
	ps2pdf $*.ps
	rm tmp*.xml

.dia.eps:
	@echo "Export $*.eps using Pango fonts"
	dia $*.dia
# Dia 0.93 crashes for some reason:
#	dia --export-to-format eps-pango $*.dia

.dia.png:
	@echo "Export $*.png using dia (scale pixels by x2.5)"
	dia $*.dia
# Dia 0.93 offers no control over resolution:
#	dia --export-to-format eps-pango $*.dia

changes.pdf: changes.dbk Render-X-license.txt catalog docbook_xslt
	$(XSLTPROC) single_fo.xsl changes.dbk | sed 's/\xa0/\&#160;/g;s/\xa9/\&#169;/' > tmp1.xml
	sed 's/Chapter\xa0//g;s/\xa0/\&#160;/g' < tmp1.xml > tmp2.xml
	$(XEP) tmp2.xml -ps changes.ps
	ps2pdf changes.ps
	rm tmp*.xml

type.pdf: type.dbk Render-X-license.txt catalog docbook_xslt
	$(XSLTPROC) single_fo.xsl type.dbk | sed 's/\xa0/\&#160;/g;s/\xa9/\&#169;/' > tmp1.xml
	sed 's/11em/24em/g' < tmp1.xml > tmp2.xml
	$(XEP) tmp2.xml -ps type.ps
	ps2pdf type.ps
	rm tmp*.xml

spec.pdf: spec.dbk \
          preprocess_fo.pl preprocess_ps.pl catalog docbook_xslt \
          $(EPS_IMAGES) Render-X-license.txt
	$(XSLTPROC) preprocess_fo.xsl spec.dbk > tmp1.xml
	$(XSLTPROC) single_fo.xsl tmp1.xml | sed 's/\xa0/\&#160;/g;s/\xa9/\&#169;/' > tmp2.xml
	perl preprocess_fo.pl tmp2.xml > tmp3.xml
	$(XEP) tmp3.xml -ps tmp3.ps
	perl preprocess_ps.pl tmp3.ps > spec.ps
	ps2pdf spec.ps
	rm tmp*.xml

spec.html: spec.dbk \
           preprocess_png.sed preprocess_html.pl catalog docbook_xslt \
           $(PNG_IMAGES)
	perl verify_lhs.pl < spec.dbk
	perl verify_terms.pl
	sed -f preprocess_png.sed spec.dbk > tmp1.xml
	$(XSLTPROC) preprocess_html.xsl tmp1.xml > tmp2.xml
	$(XSLTPROC) single_html.xsl tmp2.xml > tmp3.xml
	perl preprocess_html.pl tmp3.xml > spec.html
	#rm tmp*.xml

docbook_xslt:
	ln -s $(DOCBOOK_XSLT) docbook_xslt
