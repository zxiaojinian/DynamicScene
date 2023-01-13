using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class BakeSceneHeightGizmos : MonoBehaviour
{
    public Vector3 center;
    public Vector3Int size;

    private void OnDrawGizmos()
    {
        Gizmos.DrawWireCube(center, size);
    }
}
