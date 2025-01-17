# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg-utils

DESCRIPTION="Two-way cross-platform file synchronizer"
HOMEPAGE="https://www.seas.upenn.edu/~bcpierce/unison/"
SRC_URI="https://github.com/bcpierce00/unison/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="$(ver_cut 1-2)"
KEYWORDS="~amd64 ~arm ~ppc ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~sparc-solaris"
IUSE="debug doc gtk +ocamlopt threads"

BDEPEND="dev-lang/ocaml:=[ocamlopt?]
	doc? ( app-text/dvipsk
		app-text/ghostscript-gpl
		dev-texlive/texlive-latex )"
DEPEND="gtk? ( dev-ml/lablgtk:2=[ocamlopt?] )"
RDEPEND="gtk? ( dev-ml/lablgtk:2=[ocamlopt?]
	|| ( net-misc/x11-ssh-askpass net-misc/ssh-askpass-fullscreen ) )
	>=app-eselect/eselect-unison-0.4"

DOCS=( CONTRIB INSTALL NEWS README ROADMAP.txt TODO.txt )

src_prepare() {
	default
	# https://github.com/bcpierce00/unison/issues/416
	sed -e "/ifdef\ HEVEA/,/endif/d" -i doc/Makefile || die
	# https://github.com/bcpierce00/unison/pull/415
	sed -e "/myName/d" -i doc/docs.ml || die
}

src_compile() {
	local myconf

	if use threads; then
		myconf+=( THREADS=true )
	fi

	if use debug; then
		myconf+=( DEBUGGING=true )
	fi

	if use gtk; then
		myconf+=( UISTYLE=gtk2 )
	else
		myconf+=( UISTYLE=text )
	fi

	use ocamlopt || myconf+=( NATIVE=false )

	if use doc; then
		VARTEXFONTS="${T}/fonts" emake "${myconf[@]}" CFLAGS="" HEVEA=false docs
	fi

	# Discard cflags as it will try to pass them to ocamlc...
	emake "${myconf[@]}" CFLAGS="" src
}

src_test() {
	emake test CFLAGS=""
}

src_install() {
	# install manually, since it's just too much
	# work to force the Makefile to do the right thing.
	local binname
	cd src || die
	for binname in unison unison-fsmonitor; do
		newbin ${binname} ${binname}-${SLOT}
	done

	if use gtk; then
		newicon -s scalable ../icons/U.svg ${PN}-${SLOT}.svg
		make_desktop_entry ${PN}-${SLOT} "${PN} (${SLOT})" "${PN}-${SLOT}"
	fi

	if use doc; then
		DOCS+=( ../doc/unison-manual.pdf )
		HTML_DOCS=( "${DISTDIR}/${P}-manual.html" )
	fi

	einstalldocs
}

pkg_postinst() {
	elog "Unison now uses SLOTs, so you can specify servercmd=/usr/bin/unison-${SLOT}"
	elog "in your profile files to access exactly this version over ssh."
	elog "Or you can use 'eselect unison' to set the version."
	eselect unison update || die

	if use gtk; then
		xdg_icon_cache_update
	fi
}

pkg_postrm() {
	if use gtk; then
		xdg_icon_cache_update
	fi
}
