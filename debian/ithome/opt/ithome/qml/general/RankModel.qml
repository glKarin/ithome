// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.0
//import XmlListModel 1.0
import "karin.js" as K

Item{

    property string mytype:""
    function addRank(string,myquery){
			if(myquery !== doubleDayRank) return;

        loading=true
        ranktype=myquery
        mytype=string
        rankmodel.query=myquery
        rankmodel.source=K.API.NEWSLIST.arg("rank")
        rankmodel.reload()
    }
    AddOneModel{
        id:addonemodel
        onClose: {
            if(ranktype===doubleDayRank){
                ranktype=weekRank
                addRank("周榜",weekRank)
            }else if(ranktype===weekRank){
                ranktype=weekCommentRank
                addRank("周评",weekCommentRank)
            }else if(ranktype===weekCommentRank){
                ranktype=monthRank
                addRank("月评",monthRank)
            }else {
                loading=false
                return
            }
        }
    }
    AddXmlModel{
        id:rankmodel
        query:doubleDayRank

        onStatusChanged: {
            if(status==XmlListModel.Ready&&count>0)
            {
                listmodel.append({
                             "title":"",
                             "m_url":"",
                             "image":"",
                             "description":"",
                             "detail":"",
                             "newsid":"",
                             "hitcount":"",
                             "commentcount":"",
                             "postdate":"",
                             "newssource":"",
                             "newsauthor":"",
                             "isHighlight":true,
                             "m_text":mytype,
                             "loaderSource": "MyLiseComponent.qml"
                            })
                for(var i=0;i<rankmodel.count;++i){
                    utility.inQueue(get(i).newsid)
                }
                addonemodel.addone(-1,"rank")
            }
            else if(status==XmlListModel.Loading)
            {
                //console.log("addModel status:Loading,post url="+addxmlmodel.source)
            }
        }
    }

}
