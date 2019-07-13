// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.0
//import myXmlListModel 1.0
import QtWebKit 1.0
import "karin.js" as K

XmlListModel{
    id:addxmlmodel
    query:"/rss/channel/item"
    XmlRole { name: "title"; query: "title/string()" }//文章标题
    XmlRole { name: "m_url"; query: "url/string()" }//文章url
    XmlRole { name: "image"; query: "image/string()" }//文章标题图
    XmlRole { name: "newsid"; query: "newsid/string()" }//文章id
    XmlRole { name: "description"; query: "description/string()" }//内容简介
    XmlRole { name: "detail"; query: "detail/string()" }//主要内容
    XmlRole { name: "hitcount"; query: "hitcount/string()" }//人气
    XmlRole { name: "commentcount"; query: "commentcount/string()" }//评论数
    XmlRole { name: "postdate"; query: "postdate/string()" }//时间
    XmlRole { name: "newssource"; query: "newssource/string()" }//文章来源
    XmlRole { name: "newsauthor"; query: "newsauthor/string()" }//发布者

    function _BeginPost(zone, pn)
    {
			K.GetZoneNewsList(zone === "news" ? "" : zone, pn, function(xml){
				addxmlmodel.xml = xml;
				addxmlmodel.reload();
			});
			return;
    }
}
