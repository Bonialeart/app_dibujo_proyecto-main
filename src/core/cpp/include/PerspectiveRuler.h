#pragma once

#include <QObject>
#include <QPointF>

namespace artflow {

class PerspectiveRuler : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(int type READ type WRITE setType NOTIFY typeChanged)
    Q_PROPERTY(QPointF vp1 READ vp1 WRITE setVp1 NOTIFY vp1Changed)
    Q_PROPERTY(QPointF vp2 READ vp2 WRITE setVp2 NOTIFY vp2Changed)
    Q_PROPERTY(QPointF vp3 READ vp3 WRITE setVp3 NOTIFY vp3Changed)
    Q_PROPERTY(bool vp1Active READ vp1Active WRITE setVp1Active NOTIFY vp1ActiveChanged)
    Q_PROPERTY(bool vp2Active READ vp2Active WRITE setVp2Active NOTIFY vp2ActiveChanged)
    Q_PROPERTY(bool vp3Active READ vp3Active WRITE setVp3Active NOTIFY vp3ActiveChanged)

public:
    explicit PerspectiveRuler(QObject* parent = nullptr);

    bool active() const { return m_active; }
    void setActive(bool active);

    int type() const { return m_type; }
    void setType(int type);

    QPointF vp1() const { return m_vp1; }
    void setVp1(const QPointF& pt);

    QPointF vp2() const { return m_vp2; }
    void setVp2(const QPointF& pt);

    QPointF vp3() const { return m_vp3; }
    void setVp3(const QPointF& pt);

    bool vp1Active() const { return m_vp1Active; }
    void setVp1Active(bool active);

    bool vp2Active() const { return m_vp2Active; }
    void setVp2Active(bool active);

    bool vp3Active() const { return m_vp3Active; }
    void setVp3Active(bool active);

    Q_INVOKABLE QPointF snapPoint(const QPointF& currentPos, const QPointF& startPos) const;

signals:
    void activeChanged();
    void typeChanged();
    void vp1Changed();
    void vp2Changed();
    void vp3Changed();
    void vp1ActiveChanged();
    void vp2ActiveChanged();
    void vp3ActiveChanged();

private:
    double distSq(const QPointF& a, const QPointF& b) const;
    QPointF projectToVanishingPoint(const QPointF& p, const QPointF& origin, const QPointF& vp) const;

    bool m_active;
    int m_type;
    QPointF m_vp1;
    QPointF m_vp2;
    QPointF m_vp3;
    bool m_vp1Active;
    bool m_vp2Active;
    bool m_vp3Active;
};

} // namespace artflow
