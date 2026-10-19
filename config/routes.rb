RedmineSLA::Engine.routes.draw do
  resources :sla_rules, only: [:index, :new, :create, :edit, :update, :destroy]
  get 'sla_rules/:id/match', to: 'sla_rules#match', as: 'sla_rules_match'

  get 'sla_dashboard', to: 'dashboard#index'
  get 'sla_dashboard/breakdown', to: 'dashboard#breakdown'

  get 'issues/:issue_id/sla', to: 'issues#sla', as: 'issue_sla'
end
