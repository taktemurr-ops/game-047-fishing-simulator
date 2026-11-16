using UnityEngine;

namespace GameStudio.Fishing
{
    public static class PrototypeBootstrap
    {
        // Auto-starts the input/OnGUI prototype in an empty Unity scene.
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void Launch()
        {
            if (Object.FindObjectOfType<FishingPrototype>() != null) return;
            var host = new GameObject("Game Studio 100 - Fishing Prototype");
            Object.DontDestroyOnLoad(host);
            host.AddComponent<FishingPrototype>();
        }
    }
}
