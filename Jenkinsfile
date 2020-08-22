#!groovy
import groovy.json.JsonSlurperClassic
import org.apache.tools.ant.Project
import org.apache.tools.ant.ProjectHelper

node {

    def BUILD_NUMBER=env.BUILD_NUMBER
    def RUN_ARTIFACT_DIR="tests/${BUILD_NUMBER}"
    def SFDC_USERNAME
	
	//def HUB_ORG
    //def SFDC_HOST 
	
    def JWT_KEY_CRED_ID = env.Krish_server_key
	
    //def CONNECTED_APP_CONSUMER_KEY

    //def HUB_ORG=env.HUB_ORG_DH
    //def SFDC_HOST = env.SFDC_HOST_DH
    //def JWT_KEY_CRED_ID = env.JWT_CRED_ID_DH
    //def CONNECTED_APP_CONSUMER_KEY=env.CONNECTED_APP_CONSUMER_KEY_DH

    //println 'KEY IS' 
    //println JWT_KEY_CRED_ID
    //println HUB_ORG
    //println SFDC_HOST
    //println CONNECTED_APP_CONSUMER_KEY
	
	println JWT_KEY_CRED_ID
	
    //def toolbelt = tool 'toolbelt'
	def toolbelt = tool 'sfdx'

    stage('checkout source') {
        // when running in multi-branch job, one must issue this command
        checkout scm
		
    }

	
    //withCredentials([file(credentialsId: JWT_KEY_CRED_ID, variable: 'jwt_key_file')])
	//withCredentials([file(credentialsId: JWT_KEY_CRED_ID, variable: 'jwt_key_file'),
	withEnv(["HOME=${env.WORKSPACE}"]) {
		
			withCredentials([file(credentialsId: 'Krish_server_key', variable: 'jwt_key_file'),
							string(credentialsId: 'Krish_Connect_App_Consumer_Key',variable: 'CONNECTED_APP_CONSUMER_KEY'),
							string(credentialsId: 'HUB_ORG',variable: 'HUB_ORG'),
							string(credentialsId: 'SFDC_HOST',variable: 'SFDC_HOST')])	{
			
			println 'KEY IS' 
			println jwt_key_file
			println HUB_ORG
			println SFDC_HOST
			println CONNECTED_APP_CONSUMER_KEY
				
			stage('Execute Ant Script') {
				antBuildFilePathAndName = env.WORKSPACE +"\\build.xml"
				def antFile = new File(antBuildFilePathAndName)
				def project = new Project()
				project.init()
				ProjectHelper.projectHelper.parse(project, antFile)
				
				def antTargets = args - antBuildFilePathAndName
				antTargets.each
				   {
				      project.executeTarget(it)
				   }
				
				println 'ANT target diffBuilderWithGitCommit executed to make deploy-sf directory'
			}
			
			stage('Authorize DevHub') {
                		if (isUnix()) {
					rc = sh returnStatus: true, script: "${toolbelt} force:auth:jwt:grant --clientid ${CONNECTED_APP_CONSUMER_KEY} --username ${HUB_ORG} --jwtkeyfile ${jwt_key_file} --setdefaultdevhubusername --instanceurl ${SFDC_HOST}"
				}else{
					 rc = bat returnStatus: true, script: "\"${toolbelt}\" force:auth:jwt:grant --clientid ${CONNECTED_APP_CONSUMER_KEY} --username ${HUB_ORG} --jwtkeyfile \"${jwt_key_file}\" --setdefaultdevhubusername --instanceurl ${SFDC_HOST}"
				}
				if (rc != 0) { error 'hub org authorization failed' }

				println rc
            		}
			
			
			//stage('make MDAPI Package') {
                	//	if (isUnix()) {
			//		rmsg = sh returnStdout: true, script: "${toolbelt} force:source:convert -r force-app -d manifest --json --loglevel fatal"
					
			//	}else{
			//		 rmsg = bat returnStdout: true, script: "\"${toolbelt}\" force:source:convert -r force-app -d manifest --json --loglevel fatal"
				   
			//	}
				
			//	printf rmsg
			//	println 'convert to MDAPI Package format step done'
            		//}
			
			//stage('Deploye Code') {
				
				
			//	// need to pull out assigned username
			//	if (isUnix()) {
					
			//		rmsg = sh returnStdout: true, script: "${toolbelt} force:mdapi:deploy -d manifest/. -u ${HUB_ORG} --wait 20"
			//		//rmsg = sh returnStdout: true, script: "${toolbelt} force:source:deploy -x manifest/package.xml  -u ${HUB_ORG} --wait 20"
			//	}else{
					
			//	   rmsg = bat returnStdout: true, script: "\"${toolbelt}\" force:mdapi:deploy -d manifest/. -u ${HUB_ORG} --wait 20"
			//	   //rmsg = bat returnStdout: true, script: "\"${toolbelt}\" force:source:deploy -x manifest/package.xml  -u ${HUB_ORG} --wait 20"
			//	}
				  
			//	printf rmsg
			//	println('Deployment Success')
			//	println(rmsg)
			//}
		}
	} // closing for withCredentials([file
} //closing for withEnv(["HOME=${env.WORKSPACE}"]) {
