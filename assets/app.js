/* Static, read-only sample data viewer. No network calls. */
(() => {
  'use strict';
  const data = window.CREATURE_WAR_DATA;
  if (!data || !Array.isArray(data.nodes)) return;
  const byId = new Map(data.nodes.map(x => [x.nodeId, x]));
  const pretty = {Q01:'포유류 수렵종',Q02:'장갑 사족종',Q03:'사족 절지종',Q04:'파충류종'};
  const $ = id => document.getElementById(id);
  const nodeHost = $('nodes');
  let currentSpecies='Q01', selectedNode='Q01.T0', selectedRole='Melee';
  $('m-species').textContent = String(data.metrics.species);
  $('m-nodes').textContent = String(data.metrics.baseNodes);
  $('m-roles').textContent = String(data.metrics.t3Roles);
  $('m-methods').textContent = String(data.metrics.t4Modes);
  const el=(tag,cls,text)=>{const x=document.createElement(tag);if(cls)x.className=cls;if(text!=null)x.textContent=text;return x};
  function pathTo(node) {let cur=node, out=[], seen=new Set(); while(cur&&!seen.has(cur.nodeId)){seen.add(cur.nodeId);out.unshift(cur);cur=cur.parentId?byId.get(cur.parentId):null;}return out;}
  function drawSpeciesTabs(){const host=$('speciesTabs');host.replaceChildren();Object.keys(pretty).forEach(id=>{let btn=el('button','species-tab',id+'  '+pretty[id]);btn.type='button';btn.setAttribute('role','tab');btn.setAttribute('aria-selected',String(currentSpecies===id));btn.addEventListener('click',()=>{currentSpecies=id;selectedNode=id+'.T0';drawSpeciesTabs();drawNodes();drawDetails()});host.append(btn)});}
  function drawNodes(){const query=$('search').value.trim().toLocaleLowerCase(),tier=$('tierFilter').value;const choices=data.nodes.filter(n=>n.speciesId===currentSpecies&&(tier==='ALL'||n.tier===tier)&&(!query||(n.nodeId+' '+n.name).toLocaleLowerCase().includes(query)));$('speciesHeader').textContent=currentSpecies+' / '+pretty[currentSpecies];$('visibleCount').textContent=String(choices.length);nodeHost.replaceChildren();if(!choices.length){nodeHost.append(el('div','empty-state','조건에 맞는 노드가 없습니다.'));return;}choices.forEach(n=>{const btn=el('button','node');btn.type='button';btn.setAttribute('aria-pressed',String(n.nodeId===selectedNode));btn.title=n.nodeId+' / '+n.name;const top=el('div','node-top');top.append(el('span','tier',n.tier),el('span','node-id',n.nodeId));btn.append(top,el('span','node-name',n.name));btn.addEventListener('click',()=>{selectedNode=n.nodeId;drawNodes();drawDetails();});nodeHost.append(btn)});}
  function drawDetails(){const n=byId.get(selectedNode),host=$('nodeDetail');host.replaceChildren();if(!n)return;host.append(el('h3',null,n.name),el('div','detail-id',n.nodeId),el('div','detail-label','EVOLUTION PATH'));const trail=el('div','path-list');pathTo(n).forEach((part,i,all)=>{const step=el('span','path-step'+(i===all.length-1?' path-current':''),part.name);step.title=part.nodeId;trail.append(step);if(i<all.length-1)trail.append(el('span',null,'›'));});host.append(trail,el('div','detail-label','MODEL STATUS'));host.append(el('div','detail-state',n.modelStatus));host.append(el('div','detail-label','DATA PROVENANCE'));host.append(el('p',null,'T0–T2 공개 데이터 샘플 · '+n.speciesName));}
  const roleNames=[...new Map(data.roles.map(r=>[r.t3Id,r.t3Name])).entries()];
  function drawRoleTabs(){const host=$('roleTabs');host.replaceChildren();roleNames.forEach(([id,name])=>{const btn=el('button','role-tab');btn.type='button';btn.setAttribute('role','tab');btn.setAttribute('aria-selected',String(id===selectedRole));btn.append(el('span',null,name),el('small',null,id.toUpperCase()));btn.addEventListener('click',()=>{selectedRole=id;drawRoleTabs();drawRoleMethods();});host.append(btn)});}
  function drawRoleMethods(){const sel=roleNames.find(x=>x[0]===selectedRole);$('selectedRoleName').textContent=sel?sel[1]:'—';const host=$('roleMethods');host.replaceChildren();data.roles.filter(x=>x.t3Id===selectedRole).forEach(r=>{const item=el('div','method');item.append(el('span','method-code',r.t4Id),el('strong',null,r.t4Name));host.append(item);});}
  $('search').addEventListener('input',drawNodes);$('tierFilter').addEventListener('change',drawNodes);
  drawSpeciesTabs();drawNodes();drawDetails();drawRoleTabs();drawRoleMethods();
})();
