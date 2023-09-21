# Programmable completion for the Maven mvn command under bash. Source
# this file (or on some systems add it to ~/.bash_completion and start a new
# shell) and bash's completion mechanism will know all about mvn's options!
#
# Copyright (C) 2009, Ludovic Claude <ludovic.claude@laposte.net>
# Base on git completion script, Copyright (C) 2006,2007 Shawn O. Pearce <spearce@spearce.org>
# Distributed under the GNU General Public License, version 2.0.

# Customization: you can always edit this file (as root) and add or remove plugins and options in the lists defined below.
# If you have some interesting changes, please send patches to ludovic.claude@laposte.net
# Alternatively, you can create a file called bash_completion in your ~/.m2 directory.
# This file can override any of the variables defined below (__mvnopts, __mvnoptsWithArg __mvnparams, __mvnpackaging, 
# __mvnclassifiers, __mvndefault_phases, __mvnclean_phases, __mvnsite_phases, __mvncore_plugins, __mvnpackaging_plugins,
# __mvnreporting_plugins, __mvntools_plugins, __mvnide_plugins, __mvnother_plugins, __mvncustom_plugins)
# __mvncustom_plugins is the best variable to use to add new plugins and goals
# 

__mvnopts="--also-make --also-make-dependents --file --debug --batch-mode --lax-checksums --strict-checksums --check-plugin-updates --define 
  --errors --encrypt-master-password --encrypt-password --fail-at-end --fail-fast --fail-never --help --non-recursive --no-plugin-registry 
  --no-plugin-updates --offline --activate-profiles --projects --quiet --reactor --resume-from --settings --global-settings --update-snapshots 
  --update-plugins --version --show-version"

__mvnoptsWithArg="--file|--define|--encrypt-master-password|--encrypt-password|--resume-from|--settings|--global-settings|--activate-profiles|--projects"

__mvnparams="-Dmaven.test.skip=true -Dsurefire.useFile=false -Dmaven.surefire.debug -Xdebug -Xnoagent -Djava.compiler=NONE 
  -Xrunjdwp:transport=dt_socket,address=5005,server=y,suspend=y -Dverbose -Dmaven.test.failure.ignore=true"

__mvnpackaging="pom jar maven-plugin ejb war ear rar par"
__mvnclassifiers="sources test-jar"
__mvnscopes="compile test runtime system"

# phases for the default lifecycle
__mvndefault_phases="validate 
	 initialize 
	 generate-sources 
	 process-sources 
	 generate-resources 
	 process-resources 
	 compile 
	 process-classes 
	 generate-test-sources 
	 process-test-sources 
	 generate-test-resources 
	 process-test-resources 
	 test-compile 
	 process-test-classes 
	 test 
	 package 
	 pre-integration-test 
	 integration-test 
	 post-integration-test 
	 verify 
	 install 
	 deploy"

# phases for the clean lifecycle
__mvnclean_phases="pre-clean
	 clean
	 post-clean"

# phases for the site lifecycle
__mvnsite_phases="pre-site
	 site
	 post-site
	 site-deploy"

# core plugin targets
__mvncore_plugins="clean:clean
	 clean:help
	 compiler:compile
	 compiler:testCompile
	 compiler:help
	 deploy:deploy
	 deploy:deploy-file
	 deploy:help
	 install:install
	 install:install-file
	 install:help
	 resources:resources
	 resources:testResources
	 resources:copy-resources
	 resources:help
	 site:site
	 site:deploy
	 site:run
	 site:stage
	 site:stage-deploy
	 site:attach-descriptor
	 site:jar
	 site:help
	 surefire:test
	 surefire:help
	 verifier:verify
	 verifier:help"

# packaging plugin targets
__mvnpackaging_plugins="ear:ear
	 ear:generate-application-xml
	 ear:help
	 jar:jar
	 jar:test-jar
	 jar:sign
	 jar:sign-verify
	 jar:help
	 rar:rar
	 rar:help
	 war:war
	 war:exploded
	 war:inplace
	 war:manifest
	 war:help
	 shade:shade
	 shade:help"

# reporting plugin targets
__mvnreporting_plugins="changelog:changelog
	 changelog:dev-activity
	 changelog:file-activity
	 changelog:help
	 changes:announcement-mail
	 changes:announcement-generate
	 changes:changes-report
	 changes:jira-report
	 changes:changes-validate
	 changes:help
	 checkstyle:checkstyle
	 checkstyle:check
	 checkstyle:help
	 doap:generate
	 doap:help
	 docck:check
	 docck:help
	 javadoc:javadoc
	 javadoc:test-javadoc
	 javadoc:aggregate
	 javadoc:test-aggregate
	 javadoc:jar
	 javadoc:test-jar
	 javadoc:help
	 jxr:jxr
	 jxr:test-jxr
	 jxr:help
	 pmd:pmd
	 pmd:cpd
	 pmd:check
	 pmd:cpd-check
	 pmd:help
	 project-info-reports:cim
	 project-info-reports:dependencies
	 project-info-reports:dependency-convergence
	 project-info-reports:dependency-management
	 project-info-reports:index
	 project-info-reports:issue-tracking
	 project-info-reports:license
	 project-info-reports:mailing-list
	 project-info-reports:plugin-management
	 project-info-reports:project-team
	 project-info-reports:scm
	 project-info-reports:summary
	 project-info-reports:help
	 surefire-report:report
	 surefire-report:report-only
	 surefire-report:help"

# tools plugin targets
__mvntools_plugins="ant:ant
	 ant:clean
	 ant:help
	 antrun:run
	 antrun:help
	 archetype:create
	 archetype:generate
	 archetype:create-from-project
	 archetype:crawl
	 archetype:help
	 assembly:assembly
	 assembly:directory
	 assembly:directory-single
	 assembly:single
	 assembly:help
	 dependency:copy
	 dependency:copy-dependencies
	 dependency:unpack
	 dependency:unpack-dependencies
	 dependency:resolve
	 dependency:list
	 dependency:sources
	 dependency:resolve-plugins
	 dependency:go-offline
	 dependency:purge-local-repository
	 dependency:build-classpath
	 dependency:analyze
	 dependency:analyze-dep-mgt
	 dependency:tree
	 dependency:help
	 enforcer:enforce
	 enforcer:display-info
	 enforcer:help
	 gpg:sign
	 gpg:sign-and-deploy-file
	 gpg:help
	 help:active-profiles
	 help:all-profiles
	 help:describe
	 help:effective-pom
	 help:effective-settings
	 help:evaluate
	 help:expressions
	 help:system
	 invoker:install
	 invoker:run
	 invoker:help
	 one:convert
	 one:deploy-maven-one-repository
	 one:install-maven-one-repository
	 one:maven-one-plugin
	 one:help
	 patch:apply
	 patch:help
	 pdf:pdf
	 pdf:help
	 plugin:descriptor
	 plugin:report
	 plugin:updateRegistry
	 plugin:xdoc
	 plugin:addPluginArtifactMetadata
	 plugin:helpmojo
	 plugin:help
	 release:clean
	 release:prepare
	 release:rollback
	 release:perform
	 release:stage
	 release:branch
	 release:help
	 reactor:resume
	 reactor:make
	 reactor:make-dependents
	 reactor:make-scm-changes
	 reactor:help
	 remote-resources:bundle
	 remote-resources:process
	 remote-resources:help
	 repository:bundle-create
	 repository:bundle-pack
	 repository:help
	 scm:branch
	 scm:validate
	 scm:add
	 scm:unedit
	 scm:export
	 scm:bootstrap
	 scm:changelog
	 scm:list
	 scm:checkin
	 scm:checkout
	 scm:status
	 scm:update
	 scm:diff
	 scm:update-subprojects
	 scm:edit
	 scm:tag
	 scm:help
	 source:aggregate
	 source:jar
	 source:test-jar
	 source:jar-no-fork
	 source:test-jar-no-fork
	 source:help
	 stage:copy
	 stage:help"

# IDE plugin targets
__mvnide_plugins="eclipse:clean
	 eclipse:configure-workspace
	 eclipse:eclipse
	 eclipse:help
	 eclipse:install-plugins
	 eclipse:m2eclipse
	 eclipse:make-artifacts
	 eclipse:myeclipse
	 eclipse:myeclipse-clean
	 eclipse:rad
	 eclipse:rad-clean
	 eclipse:remove-cache
	 eclipse:to-maven
	 idea:clean
	 idea:help
	 idea:idea
	 idea:module
	 idea:project
	 idea:workspace"

__mvnother_plugins="
	 plexus:app plexus:bundle-application plexus:bundle-runtime plexus:descriptor plexus:runtime plexus:service
	 jetty:run-war jetty:run
	 cargo:start cargo:stop
	 dbunit:export dbunit:operation
	 exec:exec exec:java exec:help
	 hibernate3:hbm2cfgxml hibernate3:hbm2ddl hibernate3:hbm2doc hibernate3:hbm2hbmxml hibernate3:hbm2java hibernate3:schema-export
	   hibernate3:schema-update
	 groovy:compile groovy:console groovy:execute groovy:generateStubs groovy:generateTestStubs groovy:help groovy:providers groovy:shell
	   groovy:testCompile
	 gwt:compile gwt:eclipse gwt:eclipseTest gwt:generateAsync gwt:help gwt:i18n gwt:test
	 javacc:help javacc:javacc javacc:jjdoc javacc:jjtree javacc:jjtree-javacc javacc:jtb javacc:jtb-javacc
	 jboss:configure jboss:deploy jboss:harddeploy jboss:start jboss:stop jboss:undeploy
	 jboss-packaging:esb jboss-packaging:esb-exploded jboss-packaging:har jboss-packaging:har-exploded jboss-packaging:sar jboss-packaging:sar-exploded
	   jboss-packaging:sar-inplace jboss-packaging:spring
	 jpox:enhance jpox:schema-create jpox:schema-dbinfo jpox:schema-delete jpox:schema-info jpox:schema-validate
	 make:autoreconf make:chmod make:chown make:compile make:configure make:help make:make-clean make:make-dist make:make-install make:test
	   make:validate-pom
	 nbm:autoupdate nbm:branding nbm:cluster nbm:directory nbm:jar nbm:nbm nbm:populate-repository nbm:run-ide nbm:run-platform
	 tomcat:deploy tomcat:exploded tomcat:info tomcat:inplace tomcat:list tomcat:redeploy tomcat:resources tomcat:roles tomcat:run tomcat:run-war
	   tomcat:sessions tomcat:start tomcat:stop tomcat:undeploy
	 wagon:copy wagon:download wagon:download-single wagon:help wagon:list wagon:merge-maven-repos wagon:upload wagon:upload-single
	 was6:clean was6:ejbdeploy was6:help was6:installApp was6:wsAdmin was6:wsDefaultBindings was6:wsListApps was6:wsStartApp was6:wsStartServer
	   was6:wsStopApp was6:wsStopServer was6:wsUninstallApp
	 weblogic:appc weblogic:clientgen weblogic:clientgen9 weblogic:deploy weblogic:jwsc weblogic:listapps weblogic:redeploy weblogic:servicegen
	   weblogic:start weblogic:stop weblogic:undeploy weblogic:wsdlgen"

__mvncustom_plugins=""

### End of customizable area

if [ -e ~/.m2/bash_completion ]; then
	source ~/.m2/bash_completion
fi

__mvnphases="${__mvndefault_phases} ${__mvnclean_phases} ${__mvnsite_phases}"

__mvnall_plugin_and_goals="${__mvncore_plugins} ${__mvnpackaging_plugins} ${__mvnreporting_plugins} ${__mvntools_plugins} 
  ${__mvnide_plugins} ${__mvnother_plugins} ${__mvncustom_plugins}"

__mvnplugins=$(echo ${__mvnall_plugin_and_goals} | sed -re 's/:[^ \t]+/:\n/g' | sort -u | sed 's/[\s\n]//g')

__mvncomp_1 ()
{
	local c IFS=' '$'\t'$'\n'
	for c in $1; do
		case "$c$2" in
		--*=*) printf %s$'\n' "$c$2" ;;
		*.)    printf %s$'\n' "$c$2" ;;
		*)     printf %s$'\n' "$c$2 " ;;
		esac
	done
}

__mvncomp ()
{
	local genOpt=
	if [ "$1" == "-nospace" ]; then
		genOpt="true"
		shift
	fi
	local cur="${COMP_WORDS[COMP_CWORD]}"
	if [ $# -gt 2 ]; then
		cur="$3"
	fi
	case "$cur" in
	-*=)
		COMPREPLY=()
		;;
	*)
		local IFS=$'\n'
		COMPREPLY=($(compgen -P "$2" \
			-W "$(__mvncomp_1 "$1" "$4")" \
			-- "$cur"))
		;;
	esac
}

__mvnlist_projects ()
{
	local poms=$(find . -name pom.xml -print)
	echo $poms | while read -d ' ' POM; do
		local DIR=$(dirname "$POM")
		if [[ "$DIR" != "." ]]; then
			echo "${DIR#./}"
		fi
	done
}

__mvnlist_goals ()
{
	local plugin=$1
	local pfx=""
	if [[ "$2" ]]; then
		pfx=$2
	fi
	echo ${__mvnall_plugin_and_goals} | tr ' ' '\n' | grep "$plugin" | sed "s/.*:/${pfx}/g"
}

__mvnlist_poms ()
{
	for x in `find -type f -name pom.xml -or -name *.pom` ; do echo ${x#./} ; done
}

__mvnlist_jars ()
{
	for x in `find -type f -name *.jar` ; do echo ${x#./} ; done
}

__mvnlist_prefix ()
{
	local pfx=$1 IFS=' '$'\t'$'\n'
	shift
	local list=$@
	for c in $list; do
		echo "$pfx$c"
	done
}

__mvnprefix_equals ()
{
	local cur=$1
	local pfx=""
	case "$COMP_WORDBREAKS" in
	*=*) : great ;;
	*)   pfx="${cur%%=*}=" ;;
	esac
	echo $pfx
}

__mvnprefix_colon ()
{
	local cur=$1
	local pfx=""
	case "$COMP_WORDBREAKS" in
	*:*) : great ;;
	*)   pfx="${cur%%:*}:" ;;
	esac
	echo $pfx
}

__mvnprefix_comma ()
{
	local cur=$1
	local pfx=""
	case "$COMP_WORDBREAKS" in
	*,*) : great ;;
	*)   pfx="${cur%%,*}," ;;
	esac
	echo $pfx
}

__mvnplugin_help ()
{
	local plugin=$1
	local cur="${COMP_WORDS[COMP_CWORD]}"
	cur="${cur#-D}"
	case "${cur}" in
	goal=*)
		__mvncomp "$(__mvnlist_goals $plugin)" "$(__mvnprefix_equals $cur)" "${cur#*=}"
		;;
	*)
		__mvncomp "detail lineLength= indentSize= $(__mvnlist_goals $plugin 'goal=')" "-D" "${cur}"
		;;
	esac
}

__mvnhelp_describe ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	cur="${cur#-D}"
	case "${cur}" in
	cmd=*:*)
		local plugin="${cur#*=}"
		plugin="${plugin%%:*}:"
		__mvncomp "$(__mvnlist_goals $plugin)" "$(__mvnprefix_colon $cur)" "${cur#*:}"
		;;
	cmd=*)
		__mvncomp "${__mvnphases} ${__mvnall_plugin_and_goals}" "$(__mvnprefix_equals $cur)" "${cur#*=}"
		;;
	plugin=*)
		__mvncomp "org.apache.maven.plugins:maven-" "$(__mvnprefix_equals $cur)" "${cur#*=}"
		;;
	groupId=*)
		__mvncomp "org.apache.maven.plugins" "$(__mvnprefix_equals $cur)" "${cur#*=}"
		;;
	artifactId=*)
		__mvncomp "" "$(__mvnprefix_equals $cur)" "${cur#*=}"
		;;
	*)
		# present several cmd= options to block full completion and insertion of a space
		__mvncomp "detail cmd=press cmd=tab plugin= groupId= artifactId=" "-D" "${cur}"
		;;
	esac
}

__mvndeploy_deploy ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	cur="${cur#-D}"
	__mvncomp "altDeploymentRepository= skip=true updateReleaseInfo=true" "-D" "${cur}"
}

__mvndeploy_deploy_file ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	cur="${cur#-D}"
	case "${cur}" in
	file=*)
		COMPREPLY=( $( compgen -f -P "$(__mvnprefix_equals $cur)" -- "${cur#*=}" ) )
		;;
	pomFile=*)
		__mvncomp "$(__mvnlist_poms)" "$(__mvnprefix_equals $cur)" "${cur#*=}"
		;;
	packaging=*)
		__mvncomp "${__mvnpackaging}" "$(__mvnprefix_equals $cur)" "${cur#*=}"
		;;
	*)
		local options="artifactId= classifier= description= file=press file=tab generatePom=true groupId= pomFile=press pomFile=tab repositoryId= 
		  repositoryLayout=legacy uniqueVersion=false url= version="
		options="$options $(__mvnlist_prefix 'packaging=' ${__mvnpackaging} )"
		__mvncomp "$options" "-D" "${cur}"
		;;
	esac
}

__mvninstall_install_file ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	cur="${cur#-D}"
	case "${cur}" in
	file=*)
		COMPREPLY=( $( compgen -f -P "$(__mvnprefix_equals $cur)" -- "${cur#*=}" ) )
		;;
	pomFile=*)
		__mvncomp "$(__mvnlist_poms)" "$(__mvnprefix_equals $cur)" "${cur#*=}"
		;;
	sources=*)
		__mvncomp "$(__mvnlist_jars)" "$(__mvnprefix_equals $cur)" "${cur#*=}"
		;;
	javadoc=*)
		__mvncomp "$(__mvnlist_jars)" "$(__mvnprefix_equals $cur)" "${cur#*=}"
		;;
	packaging=*)
		__mvncomp "${__mvnpackaging}" "$(__mvnprefix_equals $cur)" "${cur#*=}"
		;;
	*)
		local options="artifactId= classifier= file=press file=tab generatePom=true groupId= pomFile=press pomFile=tab
		  createChecksum=true url= version= sources=press sources=tab javadoc=press javadoc=tab"
		options="$options $(__mvnlist_prefix 'packaging=' ${__mvnpackaging} )"
		__mvncomp "$options" "-D" "${cur}"
		;;
	esac
}

__mvnexec_java ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	if [[ "${cur}" == "=" ]]; then
		cur="${COMP_WORDS[COMP_CWORD-1]}="
	fi
	cur="${cur#-Dexec.}"
	case "${cur}" in
	classpathScope=*)
		__mvncomp "${__mvnscopes}" "$(__mvnprefix_equals $cur)" "${cur#*=}"
		;;
	*)
		local options="mainClass= args= arguments= includeProjectDependencies=false includePluginDependencies=true
		 classpathScope=press classpathScope=tab
		 cleanupDaemonThreads=false daemonThreadJoinTimeout= stopUnresponsiveDaemonThreads="
		__mvncomp "$options" "-Dexec." "${cur}"
		;;
	esac
}

__mvnarchetype_generate ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	cur="${cur#-D}"
	case "${cur}" in
	basedir=*)
		COMPREPLY=( $( compgen -d -P "$(__mvnprefix_equals $cur)" -- "${cur#*=}" ) )
		;;
	*)
		local options="archetypeArtifactId= archetypeCatalog= archetypeGroupId= archetypeRepository= archetypeVersion= basedir=press basedir=tab goals= interactiveMode="
		__mvncomp "$options" "-D" "${cur}"
		;;
	esac
}

__mvndependency_x_dependencies ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	cur="${cur#-D}"
	case "${cur}" in
	classifier=*)
		__mvncomp "${__mvnclassifiers}" "$(__mvnprefix_equals $cur)" "${cur#*=}"
		;;	
	*)
		__mvncomp "$(__mvnlist_prefix 'classifier=' ${__mvnclassifiers})" "-D" "${cur}"
		;;
	esac
}

__mvndependency_resolve ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	cur="${cur#-D}"
	case "${cur}" in
	classifier=*)
		__mvncomp "${__mvnclassifiers}" "$(__mvnprefix_equals $cur)" "${cur#*=}"
		;;	
	*)
		__mvncomp "$(__mvnlist_prefix 'classifier=' ${__mvnclassifiers}) excludeArtifactIds= excludeClassifiers= excludeGroupIds=
			excludeScope= excludeTransitive=true excludeTypes= includeArtifactIds= includeClassifiers= includeGroupIds= includeScope= 
			includeTypes= markersDirectory= outputAbsoluteArtifactFilename= outputFile= outputScope=false overWriteIfNewer=false
			overWriteReleases=true overWriteSnapshots=true silent=true type=" 
			"-D" "${cur}"
		;;
	esac
}

__mvndependency_purge_local_repository ()
{
	local fuzziness="file version artifactId groupId"
	local cur="${COMP_WORDS[COMP_CWORD]}"
	cur="${cur#-D}"
	case "${cur}" in
	resolutionFuzziness=*)
		__mvncomp "${fuzziness}" "$(__mvnprefix_equals $cur)" "${cur#*=}"
		;;	
	*)
		__mvncomp "actTransitively=false exclude= reResolve=false verbose=true
			$(__mvnlist_prefix 'resolutionFuzziness=' ${fuzziness})" 
			"-D" "${cur}"
		;;
	esac
}

__mvndependency_analyze ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	cur="${cur#-D}"
	__mvncomp "ignoreNonCompile=true outputXML=true scriptableFlag= scriptableOutput=true verbose=true" "-D" "${cur}"
}

__mvndependency_analyze_dep_mgt ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	cur="${cur#-D}"
	__mvncomp "ignoreDirect=false" "-D" "${cur}"
}

__mvndependency_tree ()
{
	local tokens="whitespace standard extended"
	local cur="${COMP_WORDS[COMP_CWORD]}"
	cur="${cur#-D}"
	case "${cur}" in
	tokens=*)
		__mvncomp "${tokens}" "$(__mvnprefix_equals $cur)" "${cur#*=}"
		;;	
	*)
		__mvncomp "excludes= includes= outputFile= scope= verbose=true
			$(__mvnlist_prefix 'tokens=' ${tokens})" 
			"-D" "${cur}"
		;;
	esac
}

__mvnrelease_prepare ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	cur="${cur#-D}"
	__mvncomp "username= dryRun=true" "-D" "${cur}"
}

__mvnscm_checkin ()
{
	local versionType="branch tag revision"
	local cur="${COMP_WORDS[COMP_CWORD]}"
	cur="${cur#-D}"
	case "${cur}" in
	scmVersionType=*)
		__mvncomp "${versionType}" "$(__mvnprefix_equals $cur)" "${cur#*=}"
		;;	
	*)
		__mvncomp "username= message= passphrase= password= scmVersion= $(__mvnlist_prefix 'scmVersionType=' ${versionType})" "-D" "${cur}"
		;;
	esac
}

_mvn ()
{
	local i prev c=1 cmd option optionArg=0 cmdcomplete=0
	local cur="${COMP_WORDS[COMP_CWORD]}"
	COMPREPLY=() 

	#echo " cur $cur"

	# discover the options and the command
	while [ $c -le $COMP_CWORD ]; do
		prev=$i
		i="${COMP_WORDS[c]}"
		c=$((++c))
		optionArg=0
		# skip option argument
		if [[ $prev == @(${__mvnoptsWithArg}) ]]; then
			optionArg=1
			continue;
		fi

		#echo "c $c i '$i'"

		if [[ $cmdcomplete == -3 ]]; then
		    cmdcomplete=1 # complete command
		    break;
		fi

		if [[ "$i" == "" ]]; then
		  if [[ $cmd ]]; then
		    cmdcomplete=1 # complete command
		    break;
		  fi
		  continue
		fi

		if [[ "$i" == ":" ]]; then
		  if [[ $cmd ]]; then
		    cmdcomplete=$((cmdcomplete-1))
		    cmd="${cmd}:"
		  fi
		  continue
		fi

		case "$i" in
		--version|--help) return ;;
		-*) option="$i" ;;
		*)  if [[ ! $cmd ]]; then 
		      # incomplete command 
		      cmdcomplete=$((cmdcomplete-1))
		      cmd="$i"
		      local next=$c
		      if [[ $next -lt $COMP_CWORD ]]; then
			#echo "next ${COMP_WORDS[next]}"
		        if [[ "${COMP_WORDS[next]}" != ":" ]]; then
		          break
		        fi
		      fi
		    else
		      cmdcomplete=$((cmdcomplete-1))
		      cmd="$cmd$i"
		    fi
		    ;;
		esac
	done

	#echo "cmd $cmd cmdcomplete $cmdcomplete"

	if [[ ! $cmd && $option && ($optionArg == 0) ]]; then
		case "$option" in
		--file)
			__mvncomp "$(__mvnlist_poms)"
			return
			;;
		--define)
			__mvncomp "maven.test.skip=true"
			return
			;;
		--resume-from)
			__mvncomp "$(__mvnlist_projects)"
			return
			;;
		--projects)
			case "${cur}" in
			*,*)
				__mvncomp "$(__mvnlist_projects)" "$(__mvnprefix_comma $cur)" "${cur#*,}"
				;;
			*)	__mvncomp "$(__mvnlist_projects)"
				;;
			esac
			return
			;;
		--settings|--global-settings)
			COMPREPLY=( $( compgen -f -- $cur ) )
			return
			;;
		--*) 
			COMPREPLY=() 
			;;
		esac
	fi

	if [ $cmdcomplete -lt 0 ]; then
		#echo "incomplete cmd $cmd"
		case "${cmd}" in
		*:)
			local plugin="${cmd%%:}:"
			#echo "plugin $plugin"
			__mvncomp "$(__mvnlist_goals $plugin)" "$(__mvnprefix_colon $cmd)" ""
			;;
		*:*)
			local plugin="${cmd%%:*}:"
			#echo "plugin $plugin"
			__mvncomp "$(__mvnlist_goals $plugin)" "$(__mvnprefix_colon $cmd)" "${cmd#*:}"
			;;
		*)     __mvncomp "${__mvnphases} ${__mvnall_plugin_and_goals}" ;;
		esac
		return
	fi

	if [ -z "$cmd" ]; then
		#echo "empty cmd cur $cur"
		case "${cur}" in
		-D*=*) COMPREPLY=() ;;
		-*)    __mvncomp "${__mvnopts} ${__mvnparams}" ;;
		--*)   __mvncomp "${__mvnopts}" ;;
		*)     __mvncomp "${__mvnphases} ${__mvnall_plugin_and_goals}" ;;
		esac
		return
	fi

	#echo "cmd $cmd"

	case "$cmd" in
	*:help) 
		local plugin="${cmd%%:*}:"
		__mvnplugin_help $plugin 
		;;
	help:describe) 			__mvnhelp_describe ;;
	deploy:deploy)			__mvndeploy_deploy ;;	
	deploy:deploy-file)		__mvndeploy_deploy_file ;;	
	archetype:generate)		__mvnarchetype_generate ;;	
	dependency:copy-dependencies)	__mvndependency_x_dependencies ;;	
	dependency:unpack-dependencies)	__mvndependency_x_dependencies ;;	
	dependency:resolve)		__mvndependency_resolve ;;
	dependency:resolve-plugins)	__mvndependency_resolve ;;
	dependency:source)		__mvndependency_resolve ;;
	dependency:go-offline)		__mvndependency_resolve ;;
	dependency:purge-local-repository) __mvndependency_purge_local_repository ;;
	dependency:analyze)		__mvndependency_analyze ;;
	dependency:analyze-dep-mgt)	__mvndependency_analyze_dep_mgt ;;
	exec:java)				__mvnexec_java ;;
	install:install-file)		__mvninstall_install_file ;;
	release:prepare)		__mvnrelease_prepare ;;
	scm:checkin)			__mvnscm_checkin ;;
	*)
		;;
	esac
}

complete -o default -o nospace -F _mvn mvn mvnDebug

