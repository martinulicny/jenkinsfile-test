pipeline {
	agent any 
	environment {
		updatesOutput = 'dependency-updates.txt'
		treeOutput = 'dependency-tree.txt'
		treeConflictsOutput = 'dependency-tree-conflicts.txt'
	}
	parameters {
		string(name: 'GIT_BRANCH', defaultValue: 'master')
	}
	tools {
		maven '3.0.5'
		jdk 'jdk8'
	}
	stages {
		stage ('Checkout') {
			steps {
				git (
					branch: "${params.GIT_BRANCH}", 
					credentialsId: '533ac8f9-f6fa-4f93-b104-2bc15e6cbcc3',
					url: 'https://stash.performgroup.com/scm/javacore/core-project.git'
				)
			}
		}
		stage ('Build') {
			steps {
				sh 'mvn clean install -DskipTests'
			}
		}
		stage ('Deploy') {
			steps {
				archiveArtifacts artifacts: '**/*.jar', fingerprint: true
			}
		}
		stage ('Report') {
			steps {
				sh """
				  mvn dependency:tree -Dverbose=true -DoutputFile=tree.txt versions:display-dependency-updates -Dversions.outputFile=updates.txt;
				  |find . -name 'tree.txt' -exec cat {} \\; > ${treeOutput}
				  |egrep -o '[^(]+omitted for conflict[^)]+' ${treeOutput} | sort | uniq -c | sort -nr > ${treeConflictsOutput}
				  |for file in `find . -name 'updates.txt'` 
				  |do
				  |	parentDir="\$(basename "\$(dirname \$file)")";
				  |	echo "\$parentDir" >> ${updatesOutput}
				  |	cat \$file >> ${updatesOutput}
				  |done;
				  """.stripMargin()
				archiveArtifacts artifacts:'${updatesOutput},${treeOutput},${treeConflictsOutput}', fingerprint: true
			}
		}
	}
}