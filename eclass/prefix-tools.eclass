# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: prefix-tools.eclass
# @MAINTAINER:
# Alexei Colin <acolin@isi.edu>
# @BLURB: Install executables for using Prefix on a specific HPC clusters

# @ECLASS-VARIABLE: PREFIX_TOOLS_CLUSTER
# @REQUIRED
# @DESCRIPTION: The name of the cluster that the tools are for

# @ECLASS-VARIABLE: PREFIX_TOOLS_CLUSTERS
# @INTERNAL
# @DESCRIPTION: List of supported clusters (suffixes of package names)
PREFIX_TOOLS_CLUSTERS=(usc-discovery anl-theta olcf-summit)

# @ECLASS-VARIABLE: PREFIX_TOOLS_HOST_DIR
# @INTERNAL
# @DESCRIPTION: Installation directory for host-side tools
PREFIX_TOOLS_HOST_DIR="/ptools"

# @ECLASS-VARIABLE: PREFIX_TOOLS_DIR
# @INTERNAL
# @DESCRIPTION: Installation directory for all prefix-tools stuff
PREFIX_TOOLS_DIR="/usr/lib/prefix-tools"

EGIT_REPO_URI="https://github.com/ISI-apex/casper-utils.git"
EGIT_SUBMODULES=()

inherit git-r3

DESCRIPTION="Tools for running Gentoo Prefix on ${PREFIX_TOOLS_CLUSTER} cluster"
HOMEPAGE="https://github.com/ISI-apex/casper-utils"
SLOT="0"
LICENSE="GPL-3"
IUSE=""

S="${WORKDIR}/${P}/prefix-tools/clusters"

EXPORT_FUNCTIONS src_install

prefix-tools_get_conflicts() {
	local conflicts=()
	local cluster
	for cluster in "${PREFIX_TOOLS_CLUSTERS[@]}"; do
		if [[ ! ${PN} =~ ${cluster}$ ]]; then
			conflicts+=("!app-portage/prefix-tools-${cluster}")
		fi
	done
	echo "${conflicts[@]}"
}

prefix-tools_doexe_dir() {
	local dir="$1"
	local dest="$2"
	if [[ -d "${dir}" && -n "$(ls -A "${dir}")" ]]; then
		exeinto "${dest}"
		for b in ${dir}/*; do
			if [[ -L  "${b}" ]]
			then
				local tgt="$(realpath "${b}")"
				dosym "$(basename "${tgt}")" \
					${dest}/$(basename "${b}")
			elif [[ -f "${b}" ]]
			then
				doexe ${b}
			else
				echo "WARNING: path ignored (neither file nor symlink): ${b}" 1>&2
			fi
		done
	fi
}

prefix-tools_src_install() {
	prefix-tools_doexe_dir "${PREFIX_TOOLS_CLUSTER}/host" \
		"${PREFIX_TOOLS_HOST_DIR}"

	local exec_path="${PREFIX_TOOLS_DIR}/bin"
	exeinto ${exec_path}

	cat >> "${T}"/01prefix-tools <<-EOF
	PATH="${EPREFIX}${exec_path}"
	EOF
	doenvd "${T}"/01prefix-tools

	prefix-tools_doexe_dir "${PREFIX_TOOLS_CLUSTER}/prefix" "${exec_path}"

	insinto /
	local etc_dir="${PREFIX_TOOLS_CLUSTER}/etc"
	if [[ -d "${etc_dir}" ]]; then
		doins -r "${etc_dir}"
	fi

	insinto "${PREFIX_TOOLS_DIR}"
	if [[ -d "${PREFIX_TOOLS_CLUSTER}/make" ]]; then
		doins -r "${PREFIX_TOOLS_CLUSTER}/make"
	fi
}
