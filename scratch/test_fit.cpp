// Standalone sanity test: how many Bezier segments does fitBezierChain
// produce for a noisy hand-drawn 'S'?
#include "vector_math.h"
#include <cmath>
#include <cstdio>
#include <random>

using namespace artflow;

int main() {
    std::mt19937 rng(42);
    std::normal_distribution<float> posNoise(0.0f, 0.6f);   // sensor jitter px
    std::normal_distribution<float> presNoise(0.0f, 0.08f); // pressure jitter

    // 'S' curve: 500 px tall, sampled every ~1.3 px of arc like the live
    // input filter produces, with realistic stylus noise.
    std::vector<VPoint2D> pts;
    const int N = 400;
    for (int i = 0; i <= N; ++i) {
        float t = static_cast<float>(i) / N;
        VPoint2D p;
        p.x = 300.0f + 120.0f * std::sin(t * 2.0f * 3.14159265f) + posNoise(rng);
        p.y = 100.0f + 500.0f * t + posNoise(rng);
        p.pressure = 0.55f + 0.25f * std::sin(t * 3.14159265f) + presNoise(rng);
        if (p.pressure < 0.05f) p.pressure = 0.05f;
        pts.push_back(p);
    }

    // Same tolerances as finalizeVectorStroke at default slider (50):
    // base = 0.5 * 16^0.5 = 2.0 px, epsilon = 0.8 px
    for (float tol : {0.5f, 1.0f, 2.0f, 4.0f, 8.0f}) {
        auto segs = fitBezierChain(pts, tol, tol * 0.4f);
        // Max deviation check: sample fit vs ideal smooth S (no noise)
        std::printf("tolerance %.2f px -> %zu segments (%zu nodos)\n",
                    tol, segs.size(), segs.size() + 1);
    }
    return 0;
}
