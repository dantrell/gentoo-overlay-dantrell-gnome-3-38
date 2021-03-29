# Distributed under the terms of the GNU General Public License v2

EAPI="7"
PYTHON_COMPAT=( python{3_6,3_7,3_8,3_9} )
VALA_MIN_API_VERSION="0.26"
VALA_USE_DEPEND="vapigen"

inherit gnome.org gnome2-utils meson python-single-r1 vala xdg

DESCRIPTION="A text editor for the GNOME desktop"
HOMEPAGE="https://wiki.gnome.org/Apps/Gedit"

LICENSE="GPL-2+ CC-BY-SA-3.0"
SLOT="0"
KEYWORDS="*"

IUSE="gtk-doc spell test +vala"

RESTRICT="!test? ( test )"

DEPEND="
	>=dev-libs/glib-2.44:2
	>=x11-libs/gtk+-3.22.0:3[introspection]
	>=x11-libs/gtksourceview-4.0.2:4[introspection]
	>=gui-libs/tepl-4.4
	>=dev-libs/libpeas-1.14.1[gtk]
	>=dev-libs/libxml2-2.5.0:2
	>=net-libs/libsoup-2.60:2.4
	x11-libs/libX11

	spell? ( >=app-text/gspell-0.2.5:0= )
	>=dev-libs/gobject-introspection-1.54:=

	${PYTHON_DEPS}
	$(python_gen_cond_dep '
		dev-python/pycairo[${PYTHON_MULTI_USEDEP}]
		>=dev-python/pygobject-3:3[cairo,${PYTHON_MULTI_USEDEP}]
		dev-libs/libpeas[python,${PYTHON_SINGLE_USEDEP}]
	')
"
RDEPEND="${DEPEND}
	x11-themes/adwaita-icon-theme
	gnome-base/gsettings-desktop-schemas
	gnome-base/gvfs
"
BDEPEND="
	${vala_depend}
	app-text/docbook-xml-dtd:4.1.2
	gtk-doc? ( >=dev-util/gtk-doc-1 )
	dev-util/itstool
	>=sys-devel/gettext-0.18
	virtual/pkgconfig
"
PATCHES=(
	"${FILESDIR}"/${PN}-3.38.0-make-spell-optional.patch
)

pkg_setup() {
	python-single-r1_pkg_setup
}

src_prepare() {
	use vala && vala_src_prepare
	xdg_src_prepare
}

src_configure() {
	local emesonargs=(
		$(meson_use gtk-doc gtk_doc)
		$(meson_use test require_all_tests)
		$(meson_use spell)
	)
	meson_src_configure
}

# Only appdata and desktop file validation in v3.32.2
src_test() { :; }

src_install() {
	meson_src_install

	python_optimize
	python_optimize "${ED}/usr/$(get_libdir)/gedit/plugins/"
}

pkg_postinst() {
	xdg_pkg_postinst
	gnome2_schemas_update
}

pkg_postrm() {
	xdg_pkg_postrm
	gnome2_schemas_update
}