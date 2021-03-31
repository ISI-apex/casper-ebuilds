# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

EGIT_REPO_URI="https://github.com/openpmix/prrte.git"
EGIT_SUBMODULES=()
SNAPSHOT_POS=4

inherit conf-overlay cuda flag-o-matic git-r3 toolchain-funcs multilib multilib-minimal snapshot

if [[ "${PV}" = *9999 ]]; then
	KEYWORDS=""
else
	KEYWORDS="~amd64 ~amd64-linux ~ppc64 ~ppc64-linux"
fi

DESCRIPTION="PMIx Reference RunTime Environment (PRRTE)"
HOMEPAGE="https://pmix.org"
LICENSE="BSD"
SLOT="0"

IUSE_OPENMPI_RM="
	openmpi_rm_alps
	openmpi_rm_lsf
	openmpi_rm_pbs
	openmpi_rm_slurm"

# TODO: questionable, but we have one workaround that is conditional
IUSE_OPENMPI_FABRICS="
	openmpi_fabrics_knem
	openmpi_fabrics_ofi
	openmpi_fabrics_psm
	openmpi_fabrics_ugni
	"

IUSE="debug ipv6 ltdl +man ${IUSE_OPENMPI_RM} ${IUSE_OPENMPI_FABRICS}"

REQUIRED_USE="
	openmpi_rm_slurm? ( !openmpi_rm_pbs )
	openmpi_rm_pbs? ( !openmpi_rm_slurm )
	"

DEPEND="
	>=dev-libs/libevent-2.0.22:=[${MULTILIB_USEDEP},threads]
	>=sys-apps/hwloc-2.0.2[${MULTILIB_USEDEP}]
	>=sys-cluster/pmix-4.0.0_pre:=
	>=sys-libs/zlib-1.2.8-r1[${MULTILIB_USEDEP}]
	ltdl? ( dev-libs/libltdl:0[${MULTILIB_USEDEP}] )
	openmpi_rm_pbs? ( sys-cluster/torque )
	openmpi_rm_alps? ( sys-cluster/cray-libs )
	man? ( app-text/pandoc )
"

PATCHES=(
	"${FILESDIR}"/${PN}-2-autoconf-alps-cray-release.patch
	"${FILESDIR}"/${PN}-2-if-addr-match.patch
	"${FILESDIR}"/${PN}-2-hostfile-max-slots-for-implicit-nodes.patch
	"${FILESDIR}"/${PN}-2.9999-prun-man-dvm-uri.patch
)
MY_OFI_PATCHES=(
		"${FILESDIR}"/${PN}-2-odls-keep-fds-for-ofi-ugni.patch
)

CONF_OVERLAY_FILES=(
	"etc/prte-mca-params.conf"
)

src_prepare() {
	if use openmpi_fabrics_ofi; then
		for p in ${MY_OFI_PATCHES[@]}; do
			eapply "${p}"
		done
	fi

	default
	./autogen.pl
}

multilib_src_configure() {
	local host_ldflags

	# On ANL Theta, routed mode other than 'directi' breaks (even on debug
	# queue for 8*64 ranks). And, setting the mode at runtime via '--mca
	# routed direct' is insuffcient -- somehow this is overriden when rank
	# count is large, at least when using 'prte --daemonize && prun'.
	local excluded_components="routed-binomial,routed-debruijn,routed-radix"

	if use openmpi_rm_lsf; then
		# TODO: fetch these programatically somehow
		# Note: these libs are not available on Summit worker nodes, so
		# to build on worker nodes, we make our own copy (not very nice...)
		local lsf_dir="$EPREFIX/host/opt/ibm/spectrumcomputing/lsf/10.1.0.9"
		local lsf_libdir="${lsf_dir}/linux3.10-glibc2.17-ppc64le-csm/lib"

		# Woraround for configure failing to link against -llsf due
		# to undefined shm_open, shm_unlink symbols  (which are in -lrt)
		#
		# ( ) Option A:
		#host_ldflags+="-lrt"
		## Drop existing ${LDFLAGS} because otherwise they contain
		## -Wl,-as-needed and the above -lrt workaround does not work.
		#local drop_ldflags=1
		#
		# (*) Option B: apply the patch to autoconf to add librt
	fi

	local final_ldflags
	if [[ -n "${drop_ldflags}" ]]; then
		final_ldflags="${host_ldflags}"
	else
		final_ldflags="${LDFLAGS} ${host_ldflags}"
	fi
	echo LDFLAGS="${final_ldflags}"
	export LDFLAGS="${final_ldflags}"

	ECONF_SOURCE=${S} econf \
		--enable-pretty-print-stacktrace \
		--enable-prte-prefix-by-default \
		--enable-mca-no-build="${excluded_components}" \
		--with-hwloc="${EPREFIX}/usr" \
		--with-hwloc-libdir="${EPREFIX}/usr/$(get_libdir)" \
		--with-libevent="${EPREFIX}/usr" \
		--with-libevent-libdir="${EPREFIX}/usr/$(get_libdir)" \
		--with-pmix="${EPREFIX}/usr" \
		--with-pmix-libdir="${EPREFIX}/usr/$(get_libdir)" \
		$(use_with ltdl libltdl "${EPREFIX}/usr") \
		$(use_enable debug) \
		$(use_enable ipv6) \
		$(use_enable man man-pages) \
		$(multilib_native_use_with openmpi_rm_alps alps) \
		$(multilib_native_use_with openmpi_rm_lsf lsf "${lsf_dir}") \
		$(multilib_native_use_with openmpi_rm_lsf lsf-libdir "${lsf_libdir}") \
		$(multilib_native_use_with openmpi_rm_pbs tm) \
		$(multilib_native_use_with openmpi_rm_slurm slurm)
}

multilib_src_compile() {
	emake V=1 "$@"
}

multilib_src_install_all() {
	default

	# Remove la files, no static libs are installed and we have pkg-config
	find "${ED}" -name '*.la' -delete || die

	einstalldocs
	conf-overlay_src_install
}
