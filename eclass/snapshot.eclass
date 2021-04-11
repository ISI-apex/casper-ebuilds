# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: snapshot.eclass
# @MAINTAINER:
# Alexei Colin <ac@alexeicolin.com>
# @SUPPORTED_EAPIS: 4 5 6 7
# @BLURB:Fetch specific snapshot versions from VCS.
# @DESCRIPTION
# Supports fetching specific commit from VCS based on package version.
# of the form:
#  * 1.0.0_pYYYYMMDDHHmmSS  : the commit after release 1.0.0 before the timestamp
#  * 2.0.0_preYYYYMMDDHHmmSS: the commit of unreleased 2.0.0 before the timestamp
#
# If HHMMSS is ommitted, then 00:00:00+0000 is assumed, to make the resolving
# deterministic (as long as you don't pick a date that's in the future), since
# it's unclear how exactly git interprets `--before=YYYY-MM-DD` without a time.
#
# Timestamps are interpreted in UTC, so when viewing the log, use:
# 	TZ=UTC git log --date=iso8601-local
#
# To check what commit a timestamp corresponds to use:
# 	git rev-list HEAD --first-parent --max-count 1 \
#		--before=YYYY-MM-DDTHH:mm:SS+0000

# @ECLASS-VARIABLE: SNAPSHOT_POS
# @REQUIRED
# @DESCRIPTION:
# The index of the first version component that's part of the snapshot
# identifier. For example, for version 1.0.0_p20200101, this index is 4.

EXPORT_FUNCTIONS src_install

inherit git-r3

if [[ "$(ver_cut ${SNAPSHOT_POS})" =~ ^(pre|p) ]]
then
	SS_TS="$(ver_cut $((SNAPSHOT_POS+1)))"
	SS_TS_DATE="${SS_TS:0:4}-${SS_TS:4:2}-${SS_TS:6:2}"
	SS_TS_TIME="${SS_TS:8:2}:${SS_TS:10:2}:${SS_TS:12:2}"
	if [[ "${SS_TS_TIME}" != "::" ]]; then
		EGIT_COMMIT_DATE="${SS_TS_DATE}T${SS_TS_TIME}+0000"
	else
		EGIT_COMMIT_DATE="${SS_TS_DATE}T00:00:00+0000"
	fi
fi

snapshot_src_install() {
	local snapshot_dir="${ED}"/etc/snapshot/${CATEGORY}
	mkdir -p "${snapshot_dir}" || die
	git -C "${S}" rev-parse HEAD > "${snapshot_dir}"/${PN} || die
}
