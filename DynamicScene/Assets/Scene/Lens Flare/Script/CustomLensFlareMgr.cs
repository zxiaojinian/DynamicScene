using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace CustomLensFlare
{
    public class CustomLensFlareMgr
    {
        static CustomLensFlareMgr _instnce;
        public static CustomLensFlareMgr Instance
        {
            get
            {
                if (_instnce == null)
                {
                    _instnce = new CustomLensFlareMgr();
                }
                return _instnce;
            }
        }

        List<CustomLensFlare> _list = new List<CustomLensFlare>();
        public List<CustomLensFlare> LensFlares
        {
            get
            {
                return _list;
            }
        }

        public void AddCustomLensFlare(CustomLensFlare lensFlare)
        {
            if(!_list.Contains(lensFlare))
            {
                _list.Add(lensFlare);
            }
        }

        public void RemoveCustomLensFlare(CustomLensFlare lensFlare)
        {
            _list.Remove(lensFlare);
        }
    }
}

