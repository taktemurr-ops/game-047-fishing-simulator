using System;
using UnityEngine;

namespace GameStudio.Fishing
{
    public enum FishingState { Ready, Casting, Hooked, Landed, Escaped }

    /// <summary>Deterministic state transitions with clamped tension and time.</summary>
    [Serializable]
    public sealed class FishingSession
    {
        public FishingState State { get; private set; } = FishingState.Ready;
        public float Tension { get; private set; }
        public float Progress { get; private set; }
        public float TimeRemaining { get; private set; }
        public int Catches { get; private set; }

        public void Cast()
        {
            if (State != FishingState.Ready && State != FishingState.Landed &&
                State != FishingState.Escaped) return;
            State = FishingState.Casting;
            Tension = 0;
            Progress = 0;
            TimeRemaining = 30f;
        }

        public bool Hook()
        {
            if (State != FishingState.Casting) return false;
            State = FishingState.Hooked;
            return true;
        }

        /// <param name="reel">Whether the player is actively reeling.</param>
        /// <param name="dt">Elapsed seconds, must be nonnegative.</param>
        public void Tick(bool reel, float dt)
        {
            if (State != FishingState.Hooked) return;
            if (dt < 0 || float.IsNaN(dt) || float.IsInfinity(dt))
                throw new ArgumentOutOfRangeException(nameof(dt));
            TimeRemaining = Mathf.Max(0, TimeRemaining - dt);
            Tension = Mathf.Clamp01(Tension + (reel ? .11f : -.22f) * dt);
            if (reel && Tension < .95f)
                Progress = Mathf.Clamp01(Progress + .18f * dt);
            if (Tension >= 1f || TimeRemaining <= 0f) State = FishingState.Escaped;
            else if (Progress >= 1f) { State = FishingState.Landed; Catches++; }
        }
    }

    public sealed class FishingPrototype : MonoBehaviour
    {
        public FishingSession Session = new FishingSession();
        void Update()
        {
            if (Input.GetKeyDown(KeyCode.Space))
            {
                if (Session.State == FishingState.Casting) Session.Hook();
                else Session.Cast();
            }
            Session.Tick(Input.GetKey(KeyCode.Return), Time.deltaTime);
        }
        void OnGUI()
        {
            GUILayout.Label("Fishing prototype: Space = cast/hook, Enter = reel");
            GUILayout.Label("State: " + Session.State + "  Catches: " + Session.Catches);
            GUILayout.Label("Tension: " + Session.Tension.ToString("F2") +
                            " Progress: " + Session.Progress.ToString("F2"));
        }
    }
}
