#include "PerspectiveRuler.h"
#include <cmath>
#include <vector>
#include <algorithm>

namespace artflow {

PerspectiveRuler::PerspectiveRuler(QObject* parent)
    : QObject(parent)
    , m_active(false)
    , m_type(2)
    , m_vp1(QPointF(-1000.0, 540.0))
    , m_vp2(QPointF(2920.0, 540.0))
    , m_vp3(QPointF(960.0, -2000.0))
    , m_vp1Active(true)
    , m_vp2Active(true)
    , m_vp3Active(true)
{}

void PerspectiveRuler::setActive(bool active) {
    if (m_active != active) {
        m_active = active;
        emit activeChanged();
    }
}

void PerspectiveRuler::setType(int type) {
    if (m_type != type) {
        m_type = type;
        emit typeChanged();
    }
}

void PerspectiveRuler::setVp1(const QPointF& pt) {
    if (m_vp1 != pt) {
        m_vp1 = pt;
        emit vp1Changed();
    }
}

void PerspectiveRuler::setVp2(const QPointF& pt) {
    if (m_vp2 != pt) {
        m_vp2 = pt;
        emit vp2Changed();
    }
}

void PerspectiveRuler::setVp3(const QPointF& pt) {
    if (m_vp3 != pt) {
        m_vp3 = pt;
        emit vp3Changed();
    }
}

void PerspectiveRuler::setVp1Active(bool active) {
    if (m_vp1Active != active) {
        m_vp1Active = active;
        emit vp1ActiveChanged();
    }
}

void PerspectiveRuler::setVp2Active(bool active) {
    if (m_vp2Active != active) {
        m_vp2Active = active;
        emit vp2ActiveChanged();
    }
}

void PerspectiveRuler::setVp3Active(bool active) {
    if (m_vp3Active != active) {
        m_vp3Active = active;
        emit vp3ActiveChanged();
    }
}

double PerspectiveRuler::distSq(const QPointF& a, const QPointF& b) const {
    double dx = a.x() - b.x();
    double dy = a.y() - b.y();
    return dx * dx + dy * dy;
}

QPointF PerspectiveRuler::projectToVanishingPoint(const QPointF& p, const QPointF& origin, const QPointF& vp) const {
    QPointF direction = vp - origin;
    double len = std::sqrt(direction.x()*direction.x() + direction.y()*direction.y());
    if (len < 1e-5) return p;
    QPointF u = direction / len;
    QPointF v = p - origin;
    double projection = v.x() * u.x() + v.y() * u.y();
    return origin + u * projection;
}

QPointF PerspectiveRuler::snapPoint(const QPointF& currentPos, const QPointF& startPos) const {
    if (!m_active) {
        return currentPos;
    }

    std::vector<QPointF> candidates;

    if (m_type == 1) {
        // 1-Point Perspective: VP1, perfect horizontal, or perfect vertical
        if (m_vp1Active) {
            candidates.push_back(projectToVanishingPoint(currentPos, startPos, m_vp1));
        }
        candidates.push_back(QPointF(currentPos.x(), startPos.y())); // Horizontal line passing through startPos
        candidates.push_back(QPointF(startPos.x(), currentPos.y())); // Vertical line passing through startPos
    } else if (m_type == 2) {
        // 2-Point Perspective: VP1, VP2, or perfect vertical
        if (m_vp1Active) {
            candidates.push_back(projectToVanishingPoint(currentPos, startPos, m_vp1));
        }
        if (m_vp2Active) {
            candidates.push_back(projectToVanishingPoint(currentPos, startPos, m_vp2));
        }
        candidates.push_back(QPointF(startPos.x(), currentPos.y())); // Vertical line passing through startPos
    } else if (m_type == 3) {
        // 3-Point Perspective: VP1, VP2, or VP3
        if (m_vp1Active) {
            candidates.push_back(projectToVanishingPoint(currentPos, startPos, m_vp1));
        }
        if (m_vp2Active) {
            candidates.push_back(projectToVanishingPoint(currentPos, startPos, m_vp2));
        }
        if (m_vp3Active) {
            candidates.push_back(projectToVanishingPoint(currentPos, startPos, m_vp3));
        }
    }

    if (candidates.empty()) {
        return currentPos;
    }

    QPointF bestSnap = candidates[0];
    double bestDistSq = distSq(bestSnap, currentPos);

    for (size_t i = 1; i < candidates.size(); ++i) {
        double d = distSq(candidates[i], currentPos);
        if (d < bestDistSq) {
            bestDistSq = d;
            bestSnap = candidates[i];
        }
    }

    return bestSnap;
}

} // namespace artflow
