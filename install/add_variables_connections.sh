#!/bin/bash

NAMESPACE=default

# Get Airflow web pod to set variables
export AIRFLOW_POD=`kubectl --namespace ${NAMESPACE} get pods | grep airflow-web -m 1| cut -f1 -d' '`

# Source env we will need
source airflow_vars.env

add_variables () {
    KEY=$1
    VALUE=$2
    kubectl --namespace ${NAMESPACE} exec ${AIRFLOW_POD} -c webserver -- sh -c "/entrypoint.sh airflow variables --set ${KEY} ${VALUE}"
}

######################################
# Add variables to airflow
######################################

# Overall
add_variables kube_namespace default

# Amount
add_variables invoice_processing_amount_counter 0
add_variables invoice_processing_amount_sha 453daad491d5a905fa654b86fe584787466735ba
add_variables invoice_processing_amount_vhosts "[\\\"actprop\\\", \\\"archerinvestment\\\", \\\"archways\\\", \\\"arthurthomas\\\", \\\"athomeapartments\\\", \\\"austincapitaladvisors\\\", \\\"az1strealty\\\", \\\"baboudjianprop\\\", \\\"bandz\\\", \\\"barinvest2\\\", \\\"bayapartment\\\", \\\"blanchardandcalhoun\\\", \\\"bluediamond\\\", \\\"blumaxpartners\\\", \\\"bmoremanagement\\\", \\\"bridlewoodrecompany\\\", \\\"bristleconemgmt\\\", \\\"brokerscomm\\\", \\\"brownstonemgt\\\", \\\"bumanagement\\\", \\\"burlingtonrentals\\\", \\\"calson\\\", \\\"carsonproperties\\\", \\\"cavaliermgmt\\\", \\\"centerpoint2\\\", \\\"century21battlefield\\\", \\\"cfisandiego\\\", \\\"circum\\\", \\\"cityrentals\\\", \\\"coastlineequity\\\", \\\"coastmanagement\\\", \\\"collegehousingnw\\\", \\\"compasscommercial\\\", \\\"conradpm\\\", \\\"courtyardproperties\\\", \\\"criteriaproperties\\\", \\\"ctrcos\\\", \\\"dcslmgmt\\\", \\\"delshah\\\", \\\"discala\\\", \\\"dolphinrealestate\\\", \\\"dover\\\", \\\"dphaurora\\\", \\\"duopropertymanagement\\\", \\\"duval\\\", \\\"ebrmanagement\\\", \\\"elevatesdproperties\\\", \\\"elkal\\\", \\\"encompassmgmt\\\", \\\"eqre\\\", \\\"equilibriumprops\\\", \\\"esa\\\", \\\"firstequityassociates\\\", \\\"firstw\\\", \\\"fivepnhholdingcompany\\\", \\\"gibson\\\", \\\"gorealtyco\\\", \\\"grindstone\\\", \\\"guerrette\\\", \\\"hammerandsaw\\\", \\\"hampshire\\\", \\\"harlamert\\\", \\\"headwayhomes\\\", \\\"heymingandjohnson\\\", \\\"hpmgmtinc\\\", \\\"ihacommercial\\\", \\\"iharesidential\\\", \\\"illicre\\\", \\\"investorspmgroup\\\", \\\"investwest\\\", \\\"jaasopm\\\", \\\"josephcompanies\\\", \\\"k3mgmt\\\", \\\"keenermanagement\\\", \\\"kelemencompany\\\", \\\"kfgpropertiesinc\\\", \\\"kiermgmt\\\", \\\"kinselameri\\\", \\\"kodiakpm\\\", \\\"land\\\", \\\"lapmg\\\", \\\"libertyproperties\\\", \\\"lmt\\\", \\\"lynxproperty\\\", \\\"madisonhill\\\", \\\"marathon\\\", \\\"marshallperry\\\", \\\"mccrealty\\\", \\\"mdatkinson\\\", \\\"meridiapm\\\", \\\"mgiglobal\\\", \\\"monroeavenue\\\", \\\"motwoprop\\\", \\\"mpminc\\\", \\\"mpsmanagement\\\", \\\"mtdpropertym\\\", \\\"mth\\\", \\\"murphyproperties\\\", \\\"nai1stvalley\\\", \\\"nautilus\\\", \\\"ncm\\\", \\\"nelsonminahanrealtors\\\", \\\"nexus\\\", \\\"nido\\\", \\\"nieblerproperties\\\", \\\"northwestmanagement\\\", \\\"northwoodproperties\\\", \\\"otp\\\", \\\"parkplacemgmt\\\", \\\"pghnexus\\\", \\\"phillipsre\\\", \\\"pillarrei\\\", \\\"pingreenw\\\", \\\"pm0vacancy\\\", \\\"podmajersky\\\", \\\"port\\\", \\\"prdcproperties\\\", \\\"premierres\\\", \\\"propertyhill\\\", \\\"quorumrealestate\\\", \\\"ralstonmgmt\\\", \\\"randpmllc\\\", \\\"redgroupny\\\", \\\"redside\\\", \\\"reichlekleingroup\\\", \\\"revisiongroup\\\", \\\"rhamco1\\\", \\\"robartsproperties\\\", \\\"rockproperties\\\", \\\"rocktownrealty\\\", \\\"roostdcllc\\\", \\\"rpmco007\\\", \\\"rpmne004\\\", \\\"sagepm\\\", \\\"scopeprops\\\", \\\"sdaptbrokers\\\", \\\"sdpropmgt\\\", \\\"sierraranch\\\", \\\"silverleafpmgmt\\\", \\\"skylinenewyork\\\", \\\"spectraassociates\\\", \\\"starmetro\\\", \\\"stephensargent\\\", \\\"sternproperty\\\", \\\"stratford\\\", \\\"sunrisemgmt\\\", \\\"thecoralcompany\\\", \\\"thelestergroup\\\", \\\"theschippergroup\\\", \\\"thewildcatgroup\\\", \\\"thosdwalsh\\\", \\\"threelestate\\\", \\\"tiaoproperties\\\", \\\"tmmrealestate\\\", \\\"trilliant\\\", \\\"trionprop\\\", \\\"turnstone\\\", \\\"uniquesolutions\\\", \\\"urbanhiveproperties\\\", \\\"urbankey\\\", \\\"utopiahoamanagement\\\", \\\"utopiamanagement\\\", \\\"valcorcre\\\", \\\"valleyincomeprop\\\", \\\"valstockmanagement\\\", \\\"vanguardpropertygroup\\\", \\\"vesacommercial\\\", \\\"virtuousmg\\\", \\\"volunteerproperties\\\", \\\"vpmi\\\", \\\"wallspropmgmt\\\", \\\"waltarnold\\\", \\\"wayfinder\\\", \\\"whalenproperties\\\", \\\"whitmoremanagementllc\\\", \\\"winstarproperties\\\", \\\"woodmont\\\", \\\"wooldridge\\\"]"

# Coldstart
add_variables invoice_processing_coldstart_counter 0
add_variables invoice_processing_coldstart_sha 4776aa617c763f4f984cb2c5c9aa48381230b912
add_variables invoice_processing_coldstart_vhosts "[\\\"allied\\\"]"

# Experiments
add_variables invoice_processing_experiments_always_train	True
add_variables invoice_processing_experiments_counter	0
add_variables invoice_processing_experiments_sha    4776aa617c763f4f984cb2c5c9aa48381230b912
add_variables invoice_processing_experiments_vhosts "[\\\"allied\\\"]"

# Tester
add_variables invoice_processing_experiments_tester_always_train	True
add_variables invoice_processing_experiments_tester_counter	0
add_variables invoice_processing_experiments_tester_sha    4776aa617c763f4f984cb2c5c9aa48381230b912
add_variables invoice_processing_experiments_tester_vhosts "[\\\"allied\\\"]"

# Manual
add_variables invoice_processing_manual_always_train	True
add_variables invoice_processing_manual_counter	0
add_variables invoice_processing_manual_sha	4776aa617c763f4f984cb2c5c9aa48381230b912
add_variables invoice_processing_manual_vhosts	"[\\\"allied\\\"]"

# reference
add_variables invoice_processing_reference_counter	0
add_variables invoice_processing_reference_sha	453daad491d5a905fa654b86fe584787466735ba
add_variables invoice_processing_reference_vhosts "[\\\"actprop\\\", \\\"arthurthomas\\\", \\\"az1strealty\\\", \\\"baboudjianprop\\\", \\\"bandz\\\", \\\"blanchardandcalhoun\\\", \\\"brownstonemgt\\\", \\\"calson\\\", \\\"cavaliermgmt\\\", \\\"circum\\\", \\\"coastlineequity\\\", \\\"criteriaproperties\\\", \\\"discala\\\", \\\"duval\\\", \\\"ebrmanagement\\\", \\\"equilibriumprops\\\", \\\"hpmgmtinc\\\", \\\"ihacommercial\\\", \\\"investorspmgroup\\\", \\\"jaasopm\\\", \\\"keenermanagement\\\", \\\"land\\\", \\\"marshallperry\\\", \\\"meridiapm\\\", \\\"monroeavenue\\\", \\\"mpminc\\\", \\\"ncm\\\", \\\"premierres\\\", \\\"quorumrealestate\\\", \\\"ram\\\", \\\"randpmllc\\\", \\\"revisiongroup\\\", \\\"silverleafpmgmt\\\", \\\"starmetro\\\", \\\"thecoralcompany\\\", \\\"thelestergroup\\\", \\\"thosdwalsh\\\", \\\"trionprop\\\", \\\"valleyincomeprop\\\", \\\"virtuousmg\\\", \\\"winstarproperties\\\"]"

######################################
# Add connections to airflow
######################################

# Insert slack oauth
kubectl --namespace ${NAMESPACE} exec ${AIRFLOW_POD} -c webserver -- sh -c "/entrypoint.sh airflow connections --add --conn_id slack_connection_airflow --conn_type http --conn_password ${SLACK_OAUTH}"

