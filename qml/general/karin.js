.pragma library

var PKG = "ithome";
var PATCH = "harmattan1";
var VER = "1.2.2harmattan1";
var DEV = "karin";
var OPENREPOS_APPID = "10847";
var RELEASE = "20190709";

var API = {
	NEWS_DETAIL: "http://api.ithome.com/xml/newscontent/%1/%2.xml",
  NEWSLIST: "http://api.ithome.com/xml/newslist/%1.xml",

	ZONE_NEWSLIST: "https://m.ithome.com/api/news/newslistpageget?Tag=%1&ot=%2&page=%3",
	NEWS_DETAIL_XML: "http://api.ithome.com/rss/%1.xml",

	SEARCH: "https://m.ithome.com/api/search/searchnewsget?keyWord=%1&maxNewsId=330707&client=wap&from=&userId=",
};

function GetNewsDetail(url, suc)
{
	// /0/432/357.htm
	var p = /^\/\d+\/(\d+)\/(\d+)\.html?$/;
	var res = url.match(p);
	if(res)
	{
		var url = API.NEWS_DETAIL.arg(res[1]).arg(res[2]);
		Request(url, suc, "XML");
	}
	else
	{
		Request(API.NEWS_DETAIL_XML.arg(url), suc, "XML");
	}
}

function GetZoneNewsList(zone, pn, suc)
{
	var ts = Date.now();
	var url = API.ZONE_NEWSLIST.arg(zone).arg(ts.toFixed()).arg(pn ? pn : 1);
	Request(url, function(json){
		var query_xml = "/rss/channel/item";
		var query_json = "/Result";
		var map = {
			newsid: "newsid",
			commentcount: "commentcount",
			hitcount: "hitcount",
			description: "description",
			detail: "c",
			url: "url",
			title: "title",
			postdate: "postdate",
			image: "image",
		};
		var fakejson = MakeFakeJSON(json, query_xml, query_json, map);
		var xml = JSON2XML(fakejson);
		suc(xml);
	}, "JSON");
}

function Request(url, suc_func, type)
{
	console.log(type, url);
	var xhr = new XMLHttpRequest();
	xhr.onreadystatechange = function(){
		if(xhr.readyState == 4)
		{
			if(xhr.status == 200)
			{
				var data = xhr.responseText;
				if(type === "XML")
					data = xhr.responseXML;
				else if(type === "JSON")
					data = JSON.parse(data);
				if(typeof(suc_func) === "function") suc_func(data);
			}
			else
			{
				if(typeof(suc_func) === "function")
					suc_func(false);
			}
		}
	};
	xhr.open("GET", url);
	xhr.send();
}

function ParseNewsId(nid)
{
	var p = parseInt(nid);
	if(!isNaN(p))
		return nid;

	p = /^https?:\/\/www\.ithome\.com\/\d+\/(\d+)\/(\d+)\.html?$/;
	var arr = nid.match(p);
	if(arr)
	{
		return arr[1] + arr[2];
	}

	return false;
}

function GetNewsUrl(nid, suc)
{
	Request(API.NEWS_DETAIL_XML.arg(nid), function(xml){
		var url = getElementsByTagName(xml, "url");
		suc("http://www.ithome.com" + url[0].firstChild.nodeValue);
	}, "XML");
}

/*Object.prototype.*/ var getElementsByTagName = function(obj, name)
{
	if(!obj || !name)
		return null;

	var doc = obj.documentElement || obj;
	if(!doc)
		return null;

	var r = [];
	var f = function(o, n, arr)
	{
		if(!o || !n || !arr)
			return;
		if(o.tagName && o.tagName === n)
		{
			arr.push(o);
		}

		if(o.childNodes)
		{
			var i;
			for(i = 0; i < o.childNodes.length; i++)
			{
				f(o.childNodes[i], n, arr);
			}
		}
	}

	f(doc, name, r);
	return r;
};

function CheckForUpdates(appid, suc)
{
	var VERSION = "v1";
	var URL = "https://openrepos.net/api/";

	var APP_DETAIL = "apps/%1";

	var __HandleNameString = function(s){
		return s.replace(/[_\s]/g, "").toLowerCase();
	};

	var MakeAPIUrl = function(call_url){
    var url = URL + VERSION + "/" + call_url;
		return url;
	};

	var MakeAppDetailUrl = function(user_name, title){
		if(!user_name || !title)
			return false;
		var APP_DETAIL_URL = "https://openrepos.net/content/%1/%2";
		var un = __HandleNameString(user_name);
		var t = __HandleNameString(title);
		return APP_DETAIL_URL.arg(un).arg(t);
	};

	var s = function(data){
		var r = {};

		if(Array.isArray(data)) // ["Application not found"]
		{
			r.error = data[0];
		}
		else
		{
			r.appid = data.appid;
			r.title = data.title;
			r.updated = parseInt(data.updated);
			r.changelog = data.changelog;
			r.download = data.download;
			r.package_name = data["package"] ? data["package"].name : "";
			r.package_version = data["package"] ? data["package"].version : "";
			r.icon = data.icon ? data.icon.url : "";
			r.body = data.body;
			r.user_name = data.user ? data.user.name : "";
			r._url = MakeAppDetailUrl(r.user_name, r.title);
		}

		suc(r);
	};

	Request(MakeAPIUrl(APP_DETAIL.arg(appid)), s, "JSON");
};

function JSON2XML(json)
{
	var f_r = function(obj, tag)
	{
		var type = typeof(obj);
		var str_out = "";
		if(type === "number")
		{
			str_out += "<" + tag + ">";
			str_out += obj.toString();
			str_out += "</" + tag + ">";
		}
		else if(type === "string")
		{
			str_out += "<" + tag + ">";
			str_out += "<![CDATA[" + obj + "]]>";
			str_out += "</" + tag + ">";
		}
		else if(type === "boolean")
		{
			str_out += "<" + tag + ">";
			str_out += obj ? true : false;
			str_out += "</" + tag + ">";
		}
		else if(type === "undefined")
		{
			str_out += "<" + tag + ">";
			str_out += "</" + tag + ">";
		}
		else if(type === "object")
		{
			if(Array.isArray(obj))
			{
				for(var i in obj)
				{
					var str = f_r(obj[i],  tag);
					str_out += str;
				}
			}
			else
			{
				if(tag !== undefined)
					str_out += "<" + tag + ">";
				for(var i in obj)
				{
					var str = f_r(obj[i],  i);
					str_out += str;
				}
				if(tag !== undefined)
					str_out += "</" + tag + ">";
			}
		}
		return str_out;
	};

	return f_r(json);
}

function MakeFakeJSON(src_json, dst_path, src_path, map)
{
	var src_path_str = src_path.indexOf("/") === 0 ? src_path.substr(1) : src_path;
	var dst_path_str = dst_path.indexOf("/") === 0 ? dst_path.substr(1) : dst_path;
	var src_path_arr = src_path_str.split("/");
	var dst_path_arr = dst_path_str.split("/");
	var r = {};
	var dst = r;
	var src = src_json;
	//console.log(src_path_str,dst_path_str, src_path_arr, dst_path_arr);
	for(var i in dst_path_arr)
	{
		if(i == dst_path_arr.length - 1)
			dst[dst_path_arr[i]] = [];
		else
			dst[dst_path_arr[i]] = {};
		dst = dst[dst_path_arr[i]];
	}
	for(var i in src_path_arr)
	{
		src = src[src_path_arr[i]];
	}
	//console.log(dst, src);
	for(var i in src)
	{
		var item = {};
		for(var k in map)
		{
			item[k] = src[i][map[k]];
		}
		dst.push(item);
	}
	return r;
}
