# Distributed under the terms of the GNU General Public License v2

EAPI="7"

inherit gnome.org gnome2-utils meson vala xdg

DESCRIPTION="Disk usage browser for GNOME"
HOMEPAGE="https://wiki.gnome.org/Apps/Baobab"

LICENSE="GPL-2+ FDL-1.1+"
SLOT="0"
KEYWORDS="*"

RDEPEND="
	>=dev-libs/glib-2.44:2
	>=x11-libs/gtk+-3.20:3
"
DEPEND="${RDEPEND}"
BDEPEND="
	$(vala_depend)
	dev-util/itstool
	>=sys-devel/gettext-0.21
	virtual/pkgconfig
"

src_prepare() {
	vala_src_prepare
	xdg_src_prepare
}

pkg_postinst() {
	xdg_pkg_postinst
	gnome2_schemas_update
}

pkg_postrm() {
	xdg_pkg_postrm
	gnome2_schemas_update
}
