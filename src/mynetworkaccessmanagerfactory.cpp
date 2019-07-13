#include "mynetworkaccessmanagerfactory.h"
#include "settings.h"
#include <QUrl>
#include <QDebug>

MyNetworkAccessManagerFactory::MyNetworkAccessManagerFactory(QObject *parent) :
    QObject(parent)
{
    m_networkManager = new QNetworkAccessManager(this);
    connect(m_networkManager,SIGNAL(sslErrors(QNetworkReply*,QList<QSslError>)),this,SLOT(onIgnoreSSLErrors(QNetworkReply*,QList<QSslError>)));
}

QNetworkAccessManager* MyNetworkAccessManagerFactory::create(QObject *parent)
{
    QMutexLocker lock(&mutex);
    Q_UNUSED(lock);
    QNetworkAccessManager* manager = new NetworkAccessManager(parent);
    
    QNetworkCookieJar* cookieJar = NetworkCookieJar::GetInstance();
    manager->setCookieJar(cookieJar);
    cookieJar->setParent(0);
    return manager;
}

void MyNetworkAccessManagerFactory::onIgnoreSSLErrors(QNetworkReply *reply, QList<QSslError> error)
{
    qDebug()<<error;
    reply->ignoreSslErrors(error);
}

NetworkAccessManager::NetworkAccessManager(QObject *parent) :
    QNetworkAccessManager(parent)
{
}

QNetworkReply *NetworkAccessManager::createRequest(Operation op, const QNetworkRequest &request, QIODevice *outgoingData)
{
    QNetworkRequest req(request);
    QSslConfiguration config;

    config.setPeerVerifyMode(QSslSocket::VerifyNone);
    config.setProtocol(QSsl::TlsV1);
    req.setSslConfiguration(config);
    // set user-agent
    if (op == PostOperation){
        req.setRawHeader("User-Agent", "IDP");
    } else {
        req.setRawHeader("User-Agent", "Mozilla/5.0 (iPhone; CPU iPhone OS 7_0_4 like Mac OS X) AppleWebKit/537.51.1 (KHTML, like Gecko) Version/7.0 Mobile/11B554a Safari/9537.53");
    }
    Settings settings;
		//qDebug()<<cookieJar()->cookiesForUrl(req.url());
    //req.setRawHeader ("Cookie", settings.getValue ("userCookie","").toByteArray ());
    QNetworkReply *reply = QNetworkAccessManager::createRequest(op, req, outgoingData);
    //QNetworkCookieJar* cookieJar = NetworkCookieJar::GetInstance();
    //reply->manager ()->setCookieJar (cookieJar);
    //cookieJar->setParent (0);
    return reply;
}

NetworkCookieJar::NetworkCookieJar(QObject *parent) :
    QNetworkCookieJar(parent)
{
    //keepAliveCookie = QNetworkCookie("ka", "open");
    load ();
}

NetworkCookieJar::~NetworkCookieJar()
{
}

void NetworkCookieJar::load()
{
    QMutexLocker lock(&mutex);
    Q_UNUSED(lock);
    Settings settings;
    QByteArray data = settings.getValue("userCookie").toByteArray();
    setAllCookies(QNetworkCookie::parseCookies(data));
}

NetworkCookieJar* NetworkCookieJar::GetInstance()
{
    static NetworkCookieJar cookieJar;
    return &cookieJar;
}

void NetworkCookieJar::clearCookies()
{
    QList<QNetworkCookie> emptyList;
    setAllCookies(emptyList);
}

QList<QNetworkCookie> NetworkCookieJar::cookiesForUrl(const QUrl &url) const
{
    QMutexLocker lock(&mutex);
    Q_UNUSED(lock);
    QString url_string = url.toString ();
#ifdef _HARMATTAN
    if(url_string.indexOf ("ruanmei.com")>0||url_string.indexOf ("ithome.com")>0)
#else
    if( url_string.indexOf ("i.ruanmei.com")>0||url_string.indexOf ("www.ithome.com")>0)
#endif
		{
        Settings settings;
        QByteArray data = settings.getValue("userCookie").toByteArray();
				QList<QByteArray> cs = data.split(';');
        QList<QNetworkCookie> r; // = QNetworkCookieJar::cookiesForUrl(url);
				Q_FOREACH(const QByteArray &b, cs)
				{
					//qDebug()<<b<<QNetworkCookie::parseCookies(b);
					r << QNetworkCookie::parseCookies(b);
				}
        return r;
    }else{
        QList<QNetworkCookie> cookies = QNetworkCookieJar::cookiesForUrl(url);
        return cookies;
    }
}

bool NetworkCookieJar::setCookiesFromUrl(const QList<QNetworkCookie> &cookieList, const QUrl &url)
{
    QMutexLocker lock(&mutex);
    Q_UNUSED(lock);
    return QNetworkCookieJar::setCookiesFromUrl(cookieList, url);
}
