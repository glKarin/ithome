// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1
import com.nokia.meego 1.1
import QtWebKit 1.0
import "../general/karin.js" as K

MyPage {
    id:commentpage
    property string mysid: ""
    tools:ToolBarLayout{
        id:commentTool
        ToolIcon{
            iconId: "toolbar-back"
            opacity: night_mode?brilliance_control:1
            onClicked: {
                current_page="content"
                web.visible=false
                main.setCssToTheme()//设置css
                if(loading)
                    loading=false
                pageStack.pop()
            }
        }
        ToolIcon{
            id:upButton
            
            opacity: night_mode?brilliance_control:1
            iconSource: night_mode?"qrc:/Image/to_up_meego.png":"qrc:/Image/to_up_inverse_meego.png"
            onClicked: {
                flick1.contentY=0
            }
        }
        ToolIcon{
            id: downButton
            iconSource: night_mode?"qrc:/Image/to_down_meego.png":"qrc:/Image/to_down_inverse_meego.png"
            opacity: night_mode?brilliance_control:1
            onClicked: {
                flick1.contentY=web.height-commentpage.height
            }
        }
        ToolIcon{
            iconId: "toolbar-edit"
            opacity: night_mode?brilliance_control:1
            onClicked: {
                comment.show()
            }
        }
    }
    Flickable{
        id:flick1
        width: parent.width
        height: parent.height-(comment.isMeShow?comment.height:0)
        maximumFlickVelocity: 3000
        pressDelay:50
        flickableDirection:Flickable.VerticalFlick
        contentHeight: web.height
        contentWidth: web.width
        //NumberAnimation on contentY{ id:flickYto0; from:10;to:0;duration: 100;running: false}
        Behavior on contentY{
            NumberAnimation{
                duration: 300
                easing.type: Easing.OutQuart
            }
        }
        Connections{
            target: full?flick1:null
            onMovementStarted: {
                  main.showToolBar=false
            }
            onMovementEnded: {
                main.showToolBar=true
            }
        }
        WebView{
            id:web
            //k url:"../general/comment.html"
            visible: false
            opacity: night_mode?brilliance_control:1
            settings.javascriptEnabled: true
            settings.minimumFontSize: content_font_size
            onLoadStarted: loading=true
            width: commentpage.width
            onWidthChanged: {
                var temp=web.url
                web.url=""
                web.url=temp
                //如果屏幕方向变了
            }
            function commentFinish(msg)
            {
                evaluateJavaScript('commentFinish('+'\''+msg+'\''+','+'\''+comment.parentCommentID+'\''+')')
            }

            javaScriptWindowObjects: QtObject{
                WebView.windowObjectName: "qml"
								function _GetNewsIdHash()
								{
									return commentpage._pagetype;
								}
                function mySid()
                {
                    utility.consoleLog("html索取了新闻id")
                    return mysid
                }
                function commentReply(commentid,nickname,lou)
                {
                    if(nickname!="") {
                        comment.text = "回复#" + lou + " " + utility.fromUtf8(nickname) + ": "
                    } else {
                        comment.placeholderText = "点击回复"
                    }

                    comment.parentCommentID=commentid
                    comment.show()
                }
                function showAlert(message)
                {
                    utility.consoleLog(message)
                    showBanner(message)
                }
                function initHtmlFinisd()//初始化Html完成之后
                {
                    web.visible=true
                    //flickYto0.start()
                    loading=false
                    //utility.consoleLog(web.html)
                }
                function commentToEnd()//将评论拉到最后
                {
                    downButton.clicked()
                }
            }
            onLoadFinished: {
                web.evaluateJavaScript("initHtml()")//初始化html
            }
            onAlert: {
                utility.consoleLog(message)
            }
        }
    }
    ScrollDecorator {
        id: horizontal
       // __alwaysShowIndicator:false
        flickableItem: flick1
        //anchors { right: flick1.right; top: flick1.top }
    }
    MyComment{
        id:comment
        mysid:commentpage.mysid
        function commentClose(msg)
        {
            web.commentFinish(msg)
        }
    }
		WebView{
			id: origwebview;
			anchors.bottom: parent.bottom;
			anchors.right: parent.right;
			z: -999;
			width: 0;
			height: 0;
			visible: false;
			settings.autoLoadImages: false;
			onLoadFinished: {
				if(_CommentIFrameId)
				{
					var script = "(function(){ return pagetype; })()";
					var pagetype = evaluateJavaScript(script);
					_pagetype = pagetype;
					loading = false;
					console.log("6) Hash is " + pagetype);
					console.log("7) Go to comment page.");
          web.url = "../general/comment.html";
				}
				else
				{
					loading=true;
					var script = "(function(){ var iframe = document.getElementById('ifcomment'); var cid = iframe.getAttribute('data'); return cid; })()";
					var cid = evaluateJavaScript(script);
					_CommentIFrameId = cid;
					console.log("4) Comment iframe ID is " + cid);
					console.log("5) Getting hash...");
					origwebview.url = "http://dyn.ithome.com/comment/" + _CommentIFrameId;
				}
			}
		}
		property string _pagetype: "";
		property string _CommentIFrameId: "";
		onMysidChanged: {
			showBanner("正在获取评论信息, 请稍等.");
			web.url = "";
			_pagetype = "";
			_CommentIFrameId = "";
			console.log("1) Getting news url of desktop version...");
			loading=true;
			K.GetNewsUrl(mysid, function(url){
				loading=true;
				origwebview.url = url;
				console.log("2) Desktop version url is " + url);
				console.log("3) Getting comment iframe ID...");
			});
		}
    Component.onCompleted: main.setCssToComment()//设置css
}
