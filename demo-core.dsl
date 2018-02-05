pipeline {
	agent any 
	parameters {
		string(name: 'branch', defaultValue: 'master')
	}
	tools {
		maven 'Maven 3.0.5'
		jdk 'jdk8'
	}
	stages {
		stage {'Checkout'} {
			git branch: ${params.branch}, 
			credentialsId: 'cc912940-bd88-4259-ac0c-681887cb6db6',
			url: https://stash.performgroup.com/scm/javacore/core-project.git		
		}
		stage {'Build'} {
			sh 'mvn clean install -DskipTests'
		}
		stage { 'Deploy' } {
			archiveArtifacts artifacts: '**/*.jar', fingerprint: true
		}
		stage { 'Report' } {
			updatesOutput = 'dependency-updates.txt'
			treeOutput = 'dependency-tree.txt'
			treeConflictsOutput = 'dependency-tree-conflicts.txt'
			sh """
				  mvn dependency:tree -Dverbose=true -DoutputFile=tree.txt versions:display-dependency-updates -Dversions.outputFile=updates.txt;
				  |find . -name 'tree.txt' -exec cat {} \\; > ${treeOutput}
				  |egrep -o '[^(]+omitted for conflict[^)]+' ${treeOutput} | sort | uniq -c | sort -nr > ${treeConflictsOutput}
				  |for file in `find . -name 'updates.txt'` 
				  |do
				  |	parentDir="\$(basename "\$(dirname \$file)")";
				  |	echo "\$parentDir" >> ${updatesOutput}
				  |	cat \$file >> ${updatesOutput}
				  |done;""".stripMargin()
			archiveArtifacts artifacts:'${updatesOutput},${treeOutput},${treeConflictsOutput}', fingerprint: true
		}
	}
}